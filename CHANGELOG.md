## 0.0.1-beta

* Report bugs on github issues with specific labels,assignees, milestone
  - Automaticlly when call `listenToExceptions` method in `main` as in example
  - Manually with `report` method
* Create labels
	- GhSnitch-external for Errors not caught by Flutter Framework
	- GhSnitch-internal for Errors caught by Flutter Framework
	- Reported by GhSnitch Package for know which issues reported from this package
* Support offline case (save locally & send later when connection exist)

## 0.0.4

* Fixed show all stack issue
* Support include screenshots on report
* Used fine-grained personal access token instead of PAT

## 0.0.5
* Removed createLabels method
* Add fetch issues from GitHub
* Added string similarity package for check issue already reported
## 0.0.6

* Fix removeLastLine extension issue
* Add string similarity package
* Update client info package

## 0.0.7
* Added labels arg to listenToExceptions method