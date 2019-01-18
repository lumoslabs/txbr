# 2.0.2
* Rescue and report errors instead of letting them interrupt all uploads.

# 2.0.1
* Fix bug causing errors to be raised when processing email templates.
* Pull in-app message and popup text from both the "message" and "alert" fields (previously we were only pulling from "message").

# 2.0.0
* Support translating in-app messages and pop-ups in campaigns.
* Refactor string extraction logic.
* Refactor Braze API into separate classes for email templates and campaigns.
* More intelligently generate Transifex resources to avoid combining phrases from connected_content tags that have distinct project and resource slugs.
* Render Liquid templates and parse connected_content URLs instead of walking the AST and keeping track of variable assignments.
  - Handles the case where the project and resource slugs are directly coded in the URL and not interpolated as variables.

# 1.1.1
* Remove additional session-based API specs and dependencies.

# 1.1.0
* Use Braze REST API instead of session-based API.

# 1.0.1
* Fix bug with string-based tags.

# 1.0.0
* Birthday!
