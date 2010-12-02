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

## Import

The gollum-site executable provides the ability to import the default layout to
the current wiki. The import command will copy the required "_Layout.html", css
and javascript to the current wiki. These files must be committed to the wiki
repository before the 'generate' command will recognize them.

       $ gollum-site import

## Working

You can generate a static site from untracked/uncommitted changes by using the
"--working" flag.

       $ gollum-site generate --working

## Watch

When running the gollum-site server you can enable directory watching to update
the static site when changes are made to any of the wiki or static files. This
currently does not work for layout updates (full site regeneration is required).

       $ gollum-site serve --watch

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
