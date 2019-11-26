# 2.5.2
* Also support special Braze variables that don't have ending curlies (i.e. they are followed by filters).

# 2.5.1
* Also support special Braze variables of the form ${first_name}.

# 2.5.0
* Support campaign.${api_id} variable in connected content URLs.
* Fix issue parsing templates with special Braze variables (like the one mentioned above).

# 2.4.1
* Don't process connected_content tags that appear to contain no translations.
* Avoid uploading empty resources.

# 2.4.0
* Include metadata when reporting errors that occur while parsing templates.

# 2.3.0
* Add support for the special Braze {% abort_message(...) %} tag.

# 2.2.0
* Also extract strings from email templates attached to campaigns.

# 2.1.0
* Add support for ERB tags in config files.

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
