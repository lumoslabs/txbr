Txbr
====

[![Build Status](https://travis-ci.org/lumoslabs/txbr.svg?branch=master)](https://travis-ci.org/lumoslabs/txbr)

Txbr, a mashup of "Transifex" and "Braze", is an automation tool that facilitates translating Braze content (emails, push notifications, etc) with Transifex, a popular translation management system.

How does it work?
---

Txbr looks for specific Liquid tags in your email templates, push notifications, etc to know what translations your template contains and where to store them in Transifex. Txbr extracts source language strings (i.e. strings in English) from your templates and creates resources in Transifex. Once translations are ready, you can use Braze's Connected Content feature to make them available in your template.

Here's an example template for the impatient:

```liquid
<html>
  <head>
    {% assign project_slug = "my_transifex_project" %}
    {% assign resource_slug = "my_transifex_resource" %}
    {% connected_content https://your_txbr_server.com/strings.json?project_slug={{project_slug}}&resource_slug={{resource_slug}}&locale={{${language} | default: 'en'}}&strings_format=YML :basic_auth txbr :save strings :retry %}
  </head>
  <body>
    {{strings.header.title | default: "Buy my stuff!"}}
  </body>
</html>
```

There are several important bits in the example above:

1. Every template you would like Txbr to manage must contain these three required Liquid tags: `assign project_slug`, `assign resource_slug`, and `connected_content`. The first two correspond to the Transifex project and resource in which you would like to store the template's strings, and the third is the mechanism by which translations are fetched and inserted into the template when it is previewed or delivered.
2. The project slug should correspond to a valid Transifex project. You'll need to create the project in Transifex, then copy the slug from the URL.
3. The resource slug should be unique within the Transifex project and must only contain uppercase and lowercase letters, numbers, underscores (i.e. "_"), and dashes (i.e. "-"). It's a safe bet to simply use the template's API identifier found at the bottom of the template's configuration page. Txbr itself places no restrictons on and performs no validation against this field, so it can contain any custom slug you want.
4. The `connected_content` tag fetches translated content from Transifex using the project and resource slugs you assigned earlier in the locale of the "current" user. When previewing your template, the locale can be set in the left-hand sidebar via a simulated current user.
5. Notice the `{{strings.header.title | default: "Buy my stuff!}}` tag. This defines and fetches a string at the key `header.title`, with a default English value of "Buy my stuff!" Txbr uses this key and default value to construct the translation file it will submit to Transifex. Providing a default value allows for easy template construction and previewing, since your template probably won't be translated immediately. Braze will fall back to this value if the translation doesn't yet exist. Liquid tags that do not specify a default value will not be included in the submission to Transifex. Finally, pay close attention to the `strings.` prefix. It corresponds to the `connected_content` tag's `:save strings` option. The `:save` option tells Braze to store the translated strings in a template variable called `strings`, which can then be used to grab individual strings. The value given to `:save` must be the same value used as the key prefix. For example, simply typing `{{header.title}}` won't work.

### Enabling Translation

Template translation is enabled by default. To skip translating a given template, add the following Liquid tag to the top of your template:

```liquid
{% assign translation_enabled = false %}
```

Configuration
---

Txbr requires several configuration options in order to communicate with Braze and Transifex. Configuration is done in the YAML file format. Here's an example:

```yaml
transifex_api_username: tx_username
transifex_api_password: tx_password
projects:
  - handler_id: email-templates
    strings_format: YML
    source_lang: en
    braze_api_url: https://rest.iad-01.braze.com/ # or whatever
    braze_api_key: abc123

```

1. The `handler_id` indicates what kind of content this project should contain. In this case, we're translating email templates, the only currently supported option.
2. Your Transifex username and password should have access to the Transifex projects you want to submit content to. You can configure access via Transifex's access control system.
3. The `strings_format` option must be one of [Transifex's supported formats](https://docs.transifex.com/formats/introduction).
4. The `source_lang` option should be the language in which your source strings are written in. In other words, it should be the language in which the `default:` text is written in your template's Liquid tags.

### Using Configuration

Txbr supports two different ways of accessing configuration, raw text and a file path. In both cases, config is passed via the `TXBR_CONFIG` environment variable. Prefix the raw text or file path with the appropriate scheme, `raw://` or `file://`, to indicate which strategy Txbr should use.

#### Raw Config

Passing raw config to Txbr can be done like this:

```bash
export TXBR_CONFIG="raw://big_yaml_string_here"
```

When Txbr starts up, it will use the YAML payload that starts after `raw://`.

#### File Config

It might make more sense to store all your config in a file. Pass the path to Txbr like this:

```bash
export TXBR_CONFIG="file://path/to/config.yml"
```

When Txbr runs, it will read and parse the file at the path that comes after `file://`.

Usage
---

Txbr is both a library and a server. It provides access to Transifex resources via a single API endpoint, `strings.json`, and includes a set of rake tasks to extract strings from templates and upload them to Transifex.

### API Endpoint

Txbr provides a single API endpoint for retrieving translated content from Transifex. You'll need to stand up a Txbr server somewhere and make it publicly available on the Internet. The URL to your server will be used in the `connected_content` tag in your Braze templates (see above).

The endpoint will be available at http://your_txbr_server.com/strings.json and accepts the following required GET parameters:

1. **project_slug**: The Transifex project slug in which the resource resides.
2. **resource_slug**: The Transifex resource containing the translated content.
3. **locale**: The locale (i.e. language) to fetch translations for.
4. **strings_format**: The Transifex-supported strings format the resource was created with. In our examples, we have used "YML".

The easiest way to get up and running is to use the Txbr Docker image. Pull the image, then start it by passing your YAML configuration as an environment variable.

```bash
docker pull quay.io/lumoslabs/txbr:master
docker run -p 9300:9300 \
  -e "TXBR_CONFIG=raw://$(cat path/to/config.yml)" \
  quay.io/lumoslabs/txbr:master
```

### Rake Tasks

First, load the rake task via `require txbr/tasks`. Then run `rake txbr:upload_all`. You can also install the gem and use the provided (very simple) CLI tool: `txbr upload_all`.

Running Tests
---

Txbr uses the popular RSpec test framework and has a comprehensive set of unit tests. To run the test suite, run `bundle exec rspec`.

Requirements
---

Txbr requires an Internet connection to access the Transifex and Braze APIs.

Compatibility
---

Txdb requires Ruby 2.5.

Authors
---

This project is maintained by [Cameron Dutro](https://github.com/camertron).

License
---

Licensed under the Apache License, Version 2.0. See the LICENSE file included in this repository for the full text.
