open Cmdliner

let config_path =
  Printf.sprintf "%s/.config/dirsift/config" (Unix.getenv "HOME")

type config = {
  hot_upper_bound : int64;
  warm_upper_bound : int64;
}

let default_config =
  {
    hot_upper_bound = Timere.Duration.(make ~days:7 () |> to_seconds);
    warm_upper_bound = Timere.Duration.(make ~days:30 () |> to_seconds);
  }

let hot_upper_bound_key = "hot_upper_bound"

let warm_upper_bound_key = "warm_upper_bound"

let config : config ref = ref default_config

let config_of_toml_table (table : TomlTypes.table) : (config, string) result =
  let exception Invalid_data of string in
  try
    let hot_upper_bound =
      match
        TomlTypes.Table.(
          find_opt (Key.bare_key_of_string hot_upper_bound_key) table)
      with
      | None -> default_config.hot_upper_bound
      | Some (TomlTypes.TString s) -> (
          match Timere_parse.duration s with
          | Ok d -> Timere.Duration.to_seconds d
          | Error msg ->
            raise
              (Invalid_data
                 (Printf.sprintf "Key: %s, %s" hot_upper_bound_key msg)))
      | _ ->
        raise
          (Invalid_data
             (Printf.sprintf "Invalid data for %s" hot_upper_bound_key))
    in
    let warm_upper_bound =
      match
        TomlTypes.Table.(
          find_opt (Key.bare_key_of_string warm_upper_bound_key) table)
      with
      | None -> default_config.warm_upper_bound
      | Some (TomlTypes.TString s) -> (
          match Timere_parse.duration s with
          | Ok d -> Timere.Duration.to_seconds d
          | Error msg ->
            raise
              (Invalid_data
                 (Printf.sprintf "Key: %s, %s" warm_upper_bound_key msg)))
      | _ ->
        raise
          (Invalid_data
             (Printf.sprintf "Invalid data for %s" warm_upper_bound_key))
    in
    if warm_upper_bound < hot_upper_bound then
      raise (Invalid_data "Warm upper bound is lower than hot upper bound");
    Ok { hot_upper_bound; warm_upper_bound }
  with Invalid_data msg -> Error msg

type dir_typ =
  | Git
  | Hidden
  | Hot
  | Warm
  | Cold
  | Not of dir_typ

let most_recent_mtime_of_files_inside dir =
  FileUtil.(find True dir)
    (fun most_recent_mtime file ->
       let stat = FileUtil.stat file in
       let mtime = Int64.of_float stat.modification_time in
       max most_recent_mtime mtime)
    0L

let rec dir_matches_typ dir typ =
  try
    CCIO.File.(exists dir && is_directory dir)
    &&
    match typ with
    | Git ->
      let sub_dirs =
        try Sys.readdir dir with _ -> failwith "Failed to read directory"
      in
      Array.mem ".git" sub_dirs
    | Hidden -> dir.[0] = '.'
    | Hot -> most_recent_mtime_of_files_inside dir <= !config.hot_upper_bound
    | Warm ->
      let mtime = most_recent_mtime_of_files_inside dir in
      !config.hot_upper_bound < mtime && mtime <= !config.warm_upper_bound
    | Cold -> most_recent_mtime_of_files_inside dir > !config.warm_upper_bound
    | Not x -> not (dir_matches_typ dir x)
  with Sys_error _ -> false

let run (typs : dir_typ list) (dir : string) =
  let sub_dirs =
    try Sys.readdir dir |> Array.to_list |> List.sort_uniq String.compare
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
      ("hot", Hot);
      ("warm", Warm);
      ("cold", Cold);
      ("not-hidden", Not Hidden);
    ]
  in
  let doc =
    Printf.sprintf "$(docv) is one of %s"
      (String.concat ", " (List.map fst typs))
  in
  Arg.(value & opt_all (enum typs) [] & info [ "t"; "type" ] ~doc ~docv:"TYPE")

let dir_arg = Arg.(value & pos 0 dir "." & info [])

let cmd =
  let doc =
    "Filter directories which satisfy all directory types constraints"
  in
  (if CCIO.File.exists config_path && not (CCIO.File.is_directory config_path)
   then
     match Toml.Parser.from_filename config_path with
     | `Ok table -> (
         match config_of_toml_table table with
         | Ok config' -> config := config'
         | Error msg ->
           print_endline msg;
           exit 1)
     | `Error (msg, _) ->
       print_endline msg;
       exit 1);
  (Term.(const run $ typ_arg $ dir_arg), Term.info "dirsift" ~doc)

let () = Term.(exit @@ Term.eval cmd)
