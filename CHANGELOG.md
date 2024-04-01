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

## 0.0.8
* Added documentations

## 0.0.9
* Use connectivity package for check network
* Update readme

## 0.0.10
* Use connectivity package for check network
* Configured saved issues report
* Use device info plus package for support all platform

## 0.0.11
* Fixed bug on issue model

## 0.0.12
* Added report issue on app version milestone

## 0.0.13
* Update dependencies

## 0.0.14
* Added `GhSnitch.openReportScreen(context);` for open report screen with follow options
	- Report issue with screenshot
	- Submit comment to issue
	- Follow up issue status

## 0.0.15
* handled duplicated issues by add (+1) as comment on duplicated issues

## 0.0.16
* Fixed duplicated issues caused by pagination with using search api

## 0.0.17
* Fixed report manually issue (hotfix)

## 0.0.18
* Added maxDuplicatedReports parameter for over control on duplicated reports count
* Added labels to duplicated reports comment