# dirsift

`find` for directories

## Usage

```
dirsift -t TYPE [PATH]
```

PATH defaults to `.` if unspecified

TYPE can be one of
- `git`
- `not-git`
- `hidden`
- `not-hidden`
- `hot`
  - Directory at PATH contains >=1 file last modified within past 7 days (7 x 24 hours)
  - User configurable
- `warm`
  - Directory at PATH contains >=1 file last modified within past 30 days (30 x 24 hours), but not `hot`
  - User configurable
- `cold`
  - Directory is neither `hot` nor `warm`
