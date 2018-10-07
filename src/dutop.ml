(* ocamlopt -o dutop unix.cmxa dutop.ml *)

open Printf
open Unix.LargeFile

let version = "1.1.0"
let debug = ref false

type path = string
type kind = File | Dir

type info = {
  path : path;
  inode : int;
  kind : kind;
  child_paths : path list;
  size : int64;
}

type node = {
  info : info;
  child_nodes : node list;
  cumulated_size : int64;
  hard_link : string option;
}

type sort_by = Name | Size

let warn = ref false

let warning s =
  eprintf "Warning: %s\n%!" s

let lookup ~follow path =
  try
    let x =
      try
        if follow then
          stat path
        else
          lstat path
      with e ->
        if !warn then
          warning (sprintf "Cannot access info on file %S: %s"
                     path (Printexc.to_string e));
        raise Exit
    in
    let inode = x.st_ino in
    let kind =
      match x.st_kind with
          Unix.S_DIR -> Dir
        | Unix.S_REG -> File
        | Unix.S_LNK ->
            raise Exit
        | _ ->
            if !warn then
              warning (sprintf "Ignoring special file %s" path);
            raise Exit
    in
    let size, child_paths =
      match kind with
          Dir ->
            let a =
              try Sys.readdir path
              with e ->
                if !warn then
                  warning (sprintf "Cannot read directory %S: %s"
                             path (Printexc.to_string e));
                raise Exit
            in
            let children =
              Array.fold_right
                (fun name acc -> Filename.concat path name :: acc)
                a []
            in
            0L, children

        | File ->
            x.st_size, []
    in
    Some { path; inode; kind; child_paths; size }
  with _ -> None

let rec scan_filesystem ?(follow = false) inodes path =
  match lookup ~follow path with
      Some info ->
        let hard_link =
          try
            Some (Hashtbl.find inodes info.inode)
          with Not_found ->
            Hashtbl.add inodes info.inode path;
            None
        in
        let child_nodes =
          List.fold_left (
            fun acc path ->
              match scan_filesystem inodes path with
                  None -> acc
                | Some x -> x :: acc
          ) [] info.child_paths
        in
        let cumulated_size =
          List.fold_left (
            fun acc x ->
              if x.hard_link = None then
                Int64.add acc x.cumulated_size
              else
                acc
          ) info.size child_nodes
        in
        Some { info; child_nodes; cumulated_size; hard_link }

    | None -> None

let rec select_big_nodes min_size acc node =
  List.fold_left (
    fun acc x ->
      if x.cumulated_size >= min_size then
        select_big_nodes min_size (x :: acc) x
      else
        acc
  ) acc node.child_nodes

let get_selection ~deref_root min_fraction root_path =
  match
    scan_filesystem ~follow: deref_root (Hashtbl.create 10000) root_path
  with
      None -> 0L, []
    | Some x ->
        let total_size = x.cumulated_size in
        let min_size =
          Int64.of_float (ceil (min_fraction *. (Int64.to_float total_size)))
        in
        total_size, select_big_nodes min_size [x] x


let list_of_string s =
  let l = ref [] in
  String.iter (fun c -> l := c :: !l) s;
  List.rev !l

let string_of_list l =
  let n = List.length l in
  let s = Bytes.create n in
  let l = ref l in
  for i = 0 to n - 1 do
    Bytes.set s i (List.hd !l);
    l := List.tl !l;
  done;
  Bytes.to_string s

let comma_string_of_int64 x =
  assert (x >= 0L);
  let l = list_of_string (Int64.to_string x) in
  let rec insert = function
      a :: b :: c :: (_ :: _ as l) -> a :: b :: c :: ',' :: insert l
    | l -> l
  in
  string_of_list (List.rev (insert (List.rev l)))


let print_info_line total_size x =
  let r =
    if total_size > 0L then
      Int64.to_float x.cumulated_size /. Int64.to_float total_size
    else 1.
  in
  printf "%c %5.1f%% %21s %s%s\n"
    (match x.info.kind with Dir -> 'd' | File -> ' ')
    (100. *. r)
    (comma_string_of_int64 x.cumulated_size)
    x.info.path
    (match x.hard_link with
         None -> ""
       | Some s -> sprintf " [%s]" s)

let run bare deref_root min_fraction reverse sort_by root_path =
  let total_size, selection =
    get_selection ~deref_root min_fraction root_path in
  let cmp =
    match sort_by with
        Name ->
          (fun a b -> String.compare a.info.path b.info.path)
      | Size ->
          (fun a b -> Int64.compare a.cumulated_size b.cumulated_size)
  in
  let cmp = if reverse then (fun a b -> cmp b a) else cmp in
  let l = List.sort cmp selection in
  let print =
    if bare then
      (fun x -> printf "%s\n" x.info.path)
    else
      (print_info_line total_size)
  in
  List.iter print l

let main () =
  let bare = ref false in
  let deref_root = ref true in
  let min_fraction = ref 0.05 in
  let reverse = ref false in
  let sort_by = ref Size in
  let root = ref "." in
  let anon_fun s = root := s in
  let options = [
    "-b", Arg.Set bare,
    "
          Bare output, i.e. the output consists only in file paths,
          one per line.";

    "-d", Arg.Clear deref_root,
    "
          Do not follow the link if the root path is a symbolic link.
          The default behavior is to dereference the root path.
          Other symlinks than the root are never dereferenced regardless
          of this setting.";

    "-m", Arg.Set_float min_fraction,
    "<floating point number between 0 and 1>
          Set the minimum fraction of the total size for a node to be reported.
          The default is 0.05, i.e. only files and directories that use
          5% of the space are reported.";

    "-p", Arg.Unit (fun () -> sort_by := Name),
    "
          Sort alphabetically by path.";

    "-r", Arg.Set reverse,
    "
          Reverse sort.";

    "-s", Arg.Unit (fun () -> sort_by := Size),
    "
          Sort by increasing size (default).";

    "-version",
    Arg.Unit (fun () -> print_endline version; exit 0),
    "
          Print program's version and exit.";

    "-w",
    Arg.Set warn,
    "
          Warn against unreadable or missing files.";
  ]
  in
  let usage_msg =
    sprintf "\
Usage: %s [PATH]
%s reports all directories and regular files that use at least 5%% of the
total space.
"
      Sys.argv.(0) Sys.argv.(0)
  in
  Arg.parse options anon_fun usage_msg;
  run !bare !deref_root !min_fraction !reverse !sort_by !root

let () = main ()
