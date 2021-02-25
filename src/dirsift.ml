open Cmdliner

type dir_typ =
  | Git
  | Hidden
  | Not of dir_typ

let rec dir_matches_typ dir typ =
  CCIO.File.(exists dir && is_directory dir)
  &&
  match typ with
  | Git ->
    let sub_dirs =
      try Sys.readdir dir with _ -> failwith "Failed to read directory"
    in
    Array.mem ".git" sub_dirs
  | Hidden -> dir.[0] = '.'
  | Not x -> not (dir_matches_typ dir x)

let run (typs : dir_typ list) (dir : string) =
  let sub_dirs =
    try Sys.readdir dir |> Array.to_list
    with _ -> failwith "Failed to read directory"
  in
  sub_dirs
  |> List.filter (fun dir -> List.for_all (dir_matches_typ dir) typs)
  |> List.iter print_endline

let typ_arg =
  let typs =
    [
      ("git", Git);
      ("not-git", Not Git);
      ("hidden", Hidden);
      ("not-hidden", Not Hidden);
    ]
  in
  let doc = "$(docv) is one of git, not-git" in
  Arg.(value & opt_all (enum typs) [] & info [ "t"; "type" ] ~doc ~docv:"TYPE")

let dir_arg = Arg.(value & pos 0 dir "." & info [])

let cmd =
  let doc =
    "Filter directories which satisfy all directory types constraints"
  in
  (Term.(const run $ typ_arg $ dir_arg), Term.info "dirsift" ~doc)

let () = Term.(exit @@ Term.eval cmd)
