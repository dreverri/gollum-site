gollum-site -- A static site generator for Gollum
=================================================

## Description

Generates a static site from a [Gollum](http://github.com/github/gollum) Wiki.

## Installation

The easiest way to install gollum-site is with RubyGems:

	$ [sudo] gem install gollum-site

## Supported formats

Gollum supports several formats for wiki text. In order to generate the various
supported formats certain dependencies must be met:

* [ASCIIDoc](http://www.methods.co.nz/asciidoc/) -- `brew install asciidoc`
* [Creole](http://wikicreole.org/) -- `gem install creole`
* [Markdown](http://daringfireball.net/projects/markdown/) -- `gem install rdiscount`
* [Org](http://orgmode.org/) -- `gem install org-ruby`
* [Pod](http://search.cpan.org/dist/perl/pod/perlpod.pod) -- `Pod::Simple::HTML` comes with Perl >= 5.10. Lower versions should install Pod::Simple from CPAN.
* [RDoc](http://rdoc.sourceforge.net/)
* [ReStructuredText](http://docutils.sourceforge.net/rst.html) -- `easy_install docutils`
* [Textile](http://www.textism.com/tools/textile/) -- `gem install RedCloth`

## Usage

Static sites can be generated using the executable provided:

       $ gollum-site generate

Once a site has been generated (output to "_site" by default) you can use the
gollum-site executable to start a web server for the site:

       $ gollum-site serve

The executable provides a few options which are described in the help menu:

       $ gollum-site --help

## Static Site Templates

The static site generator uses the
[Liquid templating system](http://github.com/tobi/liquid/wiki) to render wiki
pages. The generator looks for `_Layout.html` files to use as templates. Layouts
affect all pages in their directory and any subdirectories that do not have a
layout file of their own.

A layout is a Liquid template applied to a wiki page during static site
generation with the following data made available to it:

* `wiki.base_path`       The base path of the Wiki to which the page belongs
* `page.path`            The output path of the page
* `page.content`         The formatted content of the page
* `page.title`           The title of the page
* `page.format`          The format of the page (textile, org, etc.)
* `page.author`          The author of the last edit
* `page.date`            The date of the last edit

**A note about wiki.base_path**

*tl;dr* - Don't use "." or "" as base paths. Use "./" if relative paths are required.

The application of base path differs between Gollum page links and the layout.
Gollum uses `File.join` to combine the base path and the page link. The layout simply
renders the base path provided by the user. This can result in differing URLs.

Scenario 1: Don't include a forward slash after wiki.base_path in layouts

<table border="1" cellspacing="0" cellpadding="10">
<thead>
<tr>
<th>base_path</th>
<th>Gollum Link</th>
<th>URL</th>
<th>Layout Link</th>
<th>URL</th>
</tr>
</thead>
<tbody>
<tr>
<td>"."</td>
<td>[[Page]]</td>
<td>"./Page"</td>
<td>"{{ wiki.base_path }}Page"</td>
<td>".Page"</td>
</tr>
<tr>
<td>""</td>
<td>[[Page]]</td>
<td>"/Page"</td>
<td>"{{ wiki.base_path }}Page"</td>
<td>"Page"</td>
</tr>
</tbody>
</table>

Scenario 2: Include a forward slash after wiki.base_path in layouts


<table border="1" cellspacing="0" cellpadding="10">
<thead>
<tr>
<th>base_path</th>
<th>Gollum Link</th>
<th>URL</th>
<th>Layout Link</th>
<th>URL</th>
</tr>
</thead>
<tbody>
<tr>
<td>"/"</td>
<td>[[Page]]</td>
<td>"/Page"</td>
<td>"{{ wiki.base_path }}/Page"</td>
<td>"//Page"</td>
</tr>
</tbody>
</table>

Considering scenario 2 breaks links when using the default base path it is advised
to use scenario 1 and not use "." and "" as base paths. Use "./" if relative paths
are required.

## Import

The gollum-site executable provides the ability to import the default layout to
the current wiki. The import command will copy the required "_Layout.html", css
and javascript to the current wiki. These files must be committed to the wiki
repository before the 'generate' command will recognize them unless you use the
"--working" option.

       $ gollum-site import

## Working

You can generate a static site from untracked/uncommitted changes by using the
"--working" flag.

       $ gollum-site generate --working

## Watch

When running the gollum-site server you can enable directory watching to update
the static site when changes are made to any of the wiki or static
files. This feature only works with the "serve" command.

       $ gollum-site serve --watch

This feature requires the
[directory_watcher](https://rubygems.org/gems/directory_watcher) gem.

## Sanitization

You can customize sanitization with three options:

* --allow_elements: custom elements allowed, comma separated
* --allow_attributes: custom attributes allowed, comma separated
* --allow_protocols: custom protocols in *href* allowed, comma separated

       $ gollum-site generate --allow_elements embed,object --allow_attributes src --allow_protocols irc

## Ignore File

If there is a file named `.gollumignore` in the root of the repository, the
exclusions it specifies will be used to suppress gollum-site generation
accordingly. The `.gollumignore` file uses `.gitignore` semantics.

## Example

To see gollum-site in action, let's use it to generate a static site from a
Gollum Wiki. For this example I will use the Radiant wiki:

       $ git clone git://github.com/radiant/radiant.wiki.git
       $ cd radiant.wiki
       $ gollum-site generate
       $ gollum-site serve

Now you can browse to http://localhost:8000 and view the Radiant wiki as a
static site.

If you'd like to see generate the radiant wiki with the Gollum layout:

       $ gollum-site import # imports a simple layout
       $ gollum-site generate --working # this is SLOW
       $ gollum-site serve --watch

Now you can browse to http://localhost:8000 and view the Radiant wiki.
Additionally, you can make changes to the wiki files that will automatically
update in the static site.
