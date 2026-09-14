Genealogy::Obituary::Lookup
===========================

[![Appveyor status](https://ci.appveyor.com/api/projects/status/w2kcdehjtofvt55t?svg=true)](https://ci.appveyor.com/project/nigelhorne/genealogy-obituarydailytimes)
[![CPAN](https://img.shields.io/cpan/v/Genealogy-Obituary-Lookup.svg)](http://search.cpan.org/~nhorne/Genealogy-Obituary-Lookup/)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/nigelhorne/genealogy-obituarydailytimes/test.yml?branch=master)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/7086407966497872/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/7086407966497872/heads/master/)
[![Kwalitee](https://cpants.cpanauthors.org/dist/Genealogy-Obituary-Lookup.png)](http://cpants.cpanauthors.org/dist/Genealogy-Obituary-Lookup)
[![Travis Status](https://www.travis-ci.com/nigelhorne/Genealogy-Obituary-Lookup.svg?branch=master)](https://www.travis-ci.com/nigelhorne/Genealogy-Obituary-Lookup)
[![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/intent/tweet?text=Look+up+an+obituary+#perl+#gedcom+#genealogy&url=https://github.com/nigelhorne/Genealogy-Obituary-Lookup&via=nigelhorne)

# NAME

Genealogy::Obituary::Lookup - Lookup an obituary in the ODT/Rootsweb/funeral-notices database

# VERSION

Version 0.20

# SYNOPSIS

    use Genealogy::Obituary::Lookup;

    my $obits  = Genealogy::Obituary::Lookup->new();
    my @smiths = $obits->search(last => 'Smith');
    print $smiths[0]->{'url'}, "\n";

    # Scalar context - first match only
    my $baal = $obits->search({ first => 'Eric', last => 'Baal' });
    print $baal->{'url'}, "\n" if $baal;

# SUBROUTINES/METHODS

## new

Creates a [Genealogy::Obituary::Lookup](https://metacpan.org/pod/Genealogy%3A%3AObituary%3A%3ALookup) object.

    my $obits = Genealogy::Obituary::Lookup->new();
    my $clone  = $obits->new();                        # clone with no extra args

Accepts the following optional arguments:

- `cache` - passed to [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction)
- `config_file` - path to a YAML/XML/INI configuration file whose keys
are merged into the constructor arguments at runtime, allowing deployment-time
override without code changes.
- `directory` - directory that contains `obituaries.sql`.  If a single
non-reference argument is passed to `new()`, it is taken as `directory`.
- `logger` - object with `info()` and `error()` methods (e.g.
[Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl), [Log::Any](https://metacpan.org/pod/Log%3A%3AAny)).

### EXAMPLE

    # Default: discovers data/ relative to the installed module file
    my $default = Genealogy::Obituary::Lookup->new();

    # Explicit directory (useful during development)
    my $dev = Genealogy::Obituary::Lookup->new(directory => 't/data');

    # With structured logging
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);
    my $logged = Genealogy::Obituary::Lookup->new(logger => Log::Log4perl->get_logger());

### API SPECIFICATION

#### INPUT

    {
      'directory'   => { type => 'string', optional => 1 },
      'cache'       => { type => 'any',    optional => 1 },
      'config_file' => { type => 'string', optional => 1 },
      'logger'      => { type => 'object', optional => 1,
                         must_can => [ 'info', 'error' ] }
    }

#### OUTPUT

    On success:  blessed Genealogy::Obituary::Lookup hashref
    On failure:  undef  (carp explains why)

### MESSAGES

    warn_not_dir   - <class>: <dir> is not a directory.
                     Resolution: pass a valid, readable directory.
    warn_bad_usage - use ->new() not ::new() when passing arguments.
                     Resolution: call as a class method.
    err_bad_logger - Logger must have info() and error() methods.
                     Resolution: wrap your logger in an adapter.

### PSEUDOCODE

    1. Parse arguments: accept hashref, key=>value list, or single bare string
       (treated as directory).
    2. If called as a function (::new) with no args, tolerate and self-correct;
       croak if args were given - the invocation is ambiguous.
    3. If $class is already a blessed object, clone it: merge new args into a
       copy of the existing hash and bless into the same class.
    4. Merge config-file settings via Object::Configure.
    5. Validate the logger object if provided.
    6. Resolve the data directory: explicit arg > module-relative default.
    7. Carp and return undef if the directory is missing or unreadable.
    8. Bless and return with cache_duration defaulted (overridable by caller).

## search

Searches the obituary database.

    # List context: all matching records
    my @smiths = $obits->search(last => 'Smith');
    print $smiths[0]->{'url'}, "\n";

    # Scalar context: first matching record, or undef
    my $entry = $obits->search({ first => 'John', last => 'Smith' });

The returned hashrefs always include a `url` key pointing to the source archive.

- `List context` - array of hashrefs, empty on no match.
- `Scalar context` - single hashref, or `undef` on no match.

### EXAMPLE

    my @results = $obits->search(last => 'O-Brien');
    foreach my $r (@results) {
        printf "%s %s, age %s - %s\n",
            $r->{first} // '?', $r->{last},
            $r->{age}   // 'unknown',
            $r->{url};
    }

    # With optional filters
    my $hit = $obits->search(first => 'John', middle => 'W', last => 'Coppage');

### API SPECIFICATION

#### INPUT

    {
      'last' => {
        type    => 'string',
        min     => 1,
        max     => 100,
        matches => qr/^[\w\-]+$/     # hyphens allowed, apostrophes not
      },
      'first' => {
        type     => 'string',
        optional => 1,
        min      => 1,
        max      => 100
      },
      'middle' => {
        type     => 'string',
        optional => 1,
        min      => 1,
        max      => 100
      },
      'age' => {
        type     => 'integer',
        optional => 1,
        min      => 0,
        max      => 120
      }
    }

#### OUTPUT

    Argument error:     croak
    No match (list):    ()
    No match (scalar):  undef
    Match (list):       ( HashRef, ... )   each has a 'url' key
    Match (scalar):     HashRef            has a 'url' key

### MESSAGES

    err_no_self       - search() must be called on an object (->search, not ::search).
    err_no_last       - Value for 'last' is mandatory and must be non-empty.
    err_no_obituaries - Cannot open the obituaries database; check directory path.
    (from _create_url) err_bad_source, err_no_page, err_no_source, err_no_newspaper.

### PSEUDOCODE

    1. Croak unless $self is a blessed object.
    2. Parse args with Params::Get; validate schema with Params::Validate::Strict.
    3. Explicitly croak if 'last' is undef or empty - Params::Validate::Strict
       passes undef through for defined-but-required fields.
    4. Lazily open the obituaries DB handle (once per object lifetime).
    5. Croak if the DB handle could not be initialised.
    6. List context: fetchall, attach URL, fixate string values, return list.
    7. Scalar context: fetchone, attach URL, fixate string values, return hashref.
    8. Return undef / empty list when no rows match.

# LIMITATIONS

- **Ancestry / Rootsweb archive loss.**
Only the first 18 pages of the mlarchives index are preserved on the Wayback
Machine.  Approximately 10,000+ records from later pages are unrecoverable.
- **No full-text search.**
Searches are keyed on structured fields (last, first, middle, age).  There is
no free-text obituary content to search.
- **i18n is English-only.**
The `%MESSAGES` map supports placeholder interpolation but is not backed by a
locale-selection mechanism.  A future release should route through
[Locale::Maketext](https://metacpan.org/pod/Locale%3A%3AMaketext) or [Locale::Simple](https://metacpan.org/pod/Locale%3A%3ASimple).
- **Data::Reuse fixate semantics.**
The string-interning via `Data::Reuse::fixate` on hash-slice aliases is
correct in theory (hash slices are lvalues) but depends on
`String::Intern::Internalize` modifying @\_ in place.  Verify with your
installed version if memory consumption is a concern.
- **Private method enforcement without Sub::Private.**
`_create_url` and `_i18n` enforce privacy via an inline `caller` check.
Install [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) and replace the checks for a compile-time guarantee.
- **Single-row scalar context.**
In scalar context, `search()` returns the first row from the underlying
driver.  Row order depends on [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction) and SQLite's query
plan; add an explicit ORDER BY in the driver subclass if deterministic ordering
is required.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

See [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup).

# SEE ALSO

[Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction)

- The Obituary Daily Times: [https://sites.rootsweb.com/~obituary/](https://sites.rootsweb.com/~obituary/)
- Archived Rootsweb data: [https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit](https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit)
- Recent data: [https://www.freelists.org/list/obitdailytimes](https://www.freelists.org/list/obitdailytimes)
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Genealogy-Obituary-Lookup/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

    perldoc Genealogy::Obituary::Lookup

- MetaCPAN: [https://metacpan.org/release/Genealogy-Obituary-Lookup](https://metacpan.org/release/Genealogy-Obituary-Lookup)
- RT: [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup)
- CPAN Testers' Matrix: [http://matrix.cpantesters.org/?dist=Genealogy-Obituary-Lookup](http://matrix.cpantesters.org/?dist=Genealogy-Obituary-Lookup)

# FORMAL SPECIFICATION

## new

    𝒏𝒆𝒘 : Class × Args → (Object ∪ {⊥})

    𝒏𝒆𝒘(C, A) ≙
      let D = A.directory ∨ module_data_path(C)
      in  ¬readable(D)                                           ⟹ ⊥
        ∥  A.logger ≠ ∅ ∧ ¬(can(A.logger,'info') ∧
                              can(A.logger,'error'))             ⟹ abort
        ∥  otherwise   ⟹ ⟨ cache_duration ↦ DEFAULT_CACHE_DURATION ⟩ ⊕ A

## search

    𝒔𝒆𝒂𝒓𝒄𝒉 : Object × Params → ([Obit] ∪ Obit ∪ {undef})

    𝒔𝒆𝒂𝒓𝒄𝒉(self, P) ≙
      pre  blessed(self) ∧ P.last ≠ ∅
      post wantarray ⟹ { o : Obit | match(self.db, P) } |> map(add_url)
                else ⟹ head({ o : Obit | match(self.db, P) } |> map(add_url))

    where  add_url(o) ≙ o ⊕ ⟨ url ↦ _create_url(o) ⟩

# LICENSE AND COPYRIGHT

Copyright 2020-2026 Nigel Horne.

This program is released under the following licence: GPL2
