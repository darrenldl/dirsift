(lang dune 2.9)

(name dirsift)

(generate_opam_files true)

(source
 (github darrenldl/stramon))

(authors "Darren Ldl")

(maintainers "Darren Ldl")

(license MIT)

(package
 (name dirsift)
 (synopsis "Search for directories by type")
 (description "
```
dirsift -t TYPE [PATH]
```

Subdirectories of PATH which satisfy specified TYPE requirements are listed

PATH defaults to `.` if unspecified

TYPE can be one of
- `git`
  - Directory identified as git repository
- `not-git`
- `borg`
  - Directory identified as BorgBackup backup program repository
- `not-borg`
- `restic`
  - Directory identified as Restic backup program repository
- `not-restic`
- `hidden`
  - Name of directory begins with `.`
- `not-hidden`
- `hot`
  - Directory contains >=1 file last modified within past 7 days (7 x 24 hours)
  - User configurable
- `warm`
  - Directory contains >=1 file last modified within past 30 days (30 x 24 hours), but not `hot`
  - User configurable
- `cold`
  - Directory is neither `hot` nor `warm`
- `empty`
- `not-empty`

If multiple `-t TYPE` are specified, they are connected by `and` (conjunction),
i.e. directory must satisfy all TYPE requirements to be listed
")
 (documentation https://github.com/darrenldl/dirsift)
 (depends
   ocaml
   dune
   (stramon-lib (>= "0.3.0"))
   (timedesc (>= "0.9.1"))
   (containers (>= "3.6"))
   )
 (tags
  ("strace"
   "process monitoring"
   ))
 )

