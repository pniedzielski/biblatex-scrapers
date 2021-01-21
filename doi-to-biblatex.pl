# 10.1007/978-3-662-44124-4_10

use Modern::Perl '2018';
use experimental 'switch';
use utf8;

use LWP::UserAgent;
use JSON qw( decode_json );
use Data::Dumper qw( Dumper );
use Text::BibTeX qw( BTE_REGULAR );
use Text::BibTeX::Entry;
use Text::Trim qw( trim );
use Business::ISBN;

sub doi_uri {
    my $doi = shift or die;
    return "http://dx.doi.org/$doi";  # http://api.crossref.org/works/$doi ?
}

sub doi_to_citeproc {
    my $doi = shift or die;

    my $uri = doi_uri( $doi );

    my $ua = LWP::UserAgent->new(timeout => 10);
    my $r = $ua->get( doi_uri( $doi ), Accept => 'application/citeproc+json' );

    die unless $r->is_success;

    return decode_json( $r->decoded_content );
}

sub citeproc_to_biblatex {
    my $citeproc = shift or die;

    my $entry = Text::BibTeX::Entry->new;
    $entry->set_metatype(BTE_REGULAR);

    my $type = citeproc_get_type($citeproc);
    $entry->set_type( $type );

    for ($type) {
        when ('article') {
            do_set_with($entry, 'author', \&author_behavior, $citeproc->{ author });
            do_set($entry, 'title', $citeproc->{ title });
            do_set_with($entry, 'journaltitle', \&title_split, $citeproc->{ 'container-title' });
            do_set_with($entry, 'journalsubtitle', \&subtitle_split, $citeproc->{ 'container-title' });
            do_set_with($entry, 'date', \&date_behavior, $citeproc->{ issued });

            do_set($entry, 'translator', $citeproc->{ translator });
            do_set_with($entry, 'editor', \&author_behavior, $citeproc->{ editor });
            do_set($entry, 'language', $citeproc->{ language } || 'english');
            do_set($entry, 'series', $citeproc->{ 'collection-title' });
            do_set($entry, 'volume', $citeproc->{ volume });
            do_set($entry, 'number', $citeproc->{ issue });
            do_set_with($entry, 'pages', \&pages_endash, $citeproc->{ page });
            do_set($entry, 'version', $citeproc->{ version });
            do_set($entry, 'note', $citeproc->{ extra });
            do_set($entry, 'issn', $citeproc->{ ISSN });
            do_set($entry, 'pubstate', $citeproc->{ status });
            do_set($entry, 'doi', $citeproc->{ DOI });
            do_set($entry, 'url', $citeproc->{ link }->[0]->{ URL });
            do_set_with($entry, 'urldate', \&date_behavior, $citeproc->{ accessed });

            do_set($entry, 'abstract', $citeproc->{ abstract });
            do_set($entry, 'shortjournal', $citeproc->{ 'container-title-short' } || $citeproc->{ 'short-container-title' });
        }
        when ('incollection') {
            do_set_with($entry, 'author', \&author_behavior, $citeproc->{ author });
            do_set_with($entry, 'editor', \&author_behavior, $citeproc->{ editor });
            do_set($entry, 'title', $citeproc->{ title });
            do_set_with($entry, 'booktitle', \&title_split, $citeproc->{ 'container-title' });
            do_set_with($entry, 'booksubtitle', \&subtitle_split, $citeproc->{ 'container-title' });
            do_set_with($entry, 'date', \&date_behavior, $citeproc->{ issued });

            do_set($entry, 'translator', $citeproc->{ translator });
            do_set($entry, 'language', $citeproc->{ language } || 'english');
            do_set($entry, 'volume', $citeproc->{ volume });
            do_set($entry, 'number', $citeproc->{ issue });
            do_set_with($entry, 'pages', \&pages_endash, $citeproc->{ page });
            do_set($entry, 'version', $citeproc->{ version });
            do_set($entry, 'note', $citeproc->{ extra });
            do_set($entry, 'issn', $citeproc->{ ISSN });
            do_set($entry, 'pubstate', $citeproc->{ status });
            do_set($entry, 'doi', $citeproc->{ DOI });
            do_set($entry, 'url', $citeproc->{ link }->[0]->{ URL });
            do_set_with($entry, 'urldate', \&date_behavior, $citeproc->{ accessed });

            do_set($entry, 'abstract', $citeproc->{ abstract });
        }
        when ('book') {
            do_set_with($entry, 'author', \&author_behavior, $citeproc->{ author });
            do_set($entry, 'title', $citeproc->{ title });
            do_set_with($entry, 'date', \&date_behavior, $citeproc->{ issued });

            do_set_with($entry, 'editor', \&author_behavior, $citeproc->{ editor });
            do_set($entry, 'translator', $citeproc->{ translator });
            do_set($entry, 'subtitle', $citeproc->{ subtitle });
            do_set($entry, 'language', $citeproc->{ language } || 'english');
            do_set($entry, 'volume', $citeproc->{ volume });
            do_set($entry, 'edition', $citeproc->{ edition });
            do_set($entry, 'volumes', $citeproc->{ 'number-of-volumes' });
            do_set($entry, 'series', $citeproc->{ 'collection-title' });
            do_set($entry, 'number', $citeproc->{ 'collection-number' });
            do_set($entry, 'note', $citeproc->{ extra });
            do_set($entry, 'publisher', $citeproc->{ publisher });
            do_set($entry, 'location', $citeproc->{ 'publisher-place' } || $citeproc->{ 'publisher-location' });
            do_set_with($entry, 'isbn', \&hyphen_isbn, $citeproc->{ ISBN });
            do_set($entry, 'pagetotal', $citeproc->{ 'number-of-pages' });
            do_set($entry, 'pubstate', $citeproc->{ status });
            do_set($entry, 'doi', $citeproc->{ DOI });
            do_set($entry, 'url', $citeproc->{ link }->[0]->{ URL });
            do_set_with($entry, 'urldate', \&date_behavior, $citeproc->{ accessed });

            do_set($entry, 'abstract', $citeproc->{ abstract });
            do_set($entry, 'version', $citeproc->{ version });
            do_set($entry, 'issn', $citeproc->{ ISSN });

            do_set($entry, 'shorttitle', $citeproc->{ 'container-title-short' } || $citeproc->{ 'short-container-title' });
        }
        default {
            say $type;
        }
    }

    # do_set($entry, 'doi', $citeproc->{ DOI });
    # do_set_with($entry, 'isbn', \&hyphen_isbn, $citeproc->{ ISBN });
    # do_set($entry, 'issn', $citeproc->{ ISSN });
    # do_set($entry, 'url', $citeproc->{ link }->[0]->{ URL });
    # do_set($entry, 'abstract', $citeproc->{ abstract });
    # do_set($entry, 'chapter', $citeproc->{ 'chapter-number' });
    # do_set($entry, 'title', $citeproc->{ title });
    # do_set($entry, 'subtitle', $citeproc->{ subtitle });
    # do_set($entry, 'publisher', $citeproc->{ publisher });
    # do_set($entry, 'annotation', $citeproc->{ annote });
    # do_set_with($entry, 'author', \&author_behavior, $citeproc->{ author });
    # do_set_with($entry, 'bookauthor', \&author_behavior, $citeproc->{ 'container-author' });
    # if ($type eq 'book')  { do_set($entry, 'series', $citeproc->{ 'container-title' }); }
    # else                  { do_set($entry, 'booktitle', $citeproc->{ 'container-title' }); }
    # # do_set($entry, 'date', $citeproc->{ '' });   # ?????
    # do_set($entry, 'edition', $citeproc->{ edition });
    # do_set_with($entry, 'editor', \&author_behavior, $citeproc->{ editor });
    # do_set($entry, 'eventdate', $citeproc->{ 'event-date' });
    # do_set($entry, 'eventtitle', $citeproc->{ event });
    # # # file

    # do_set($entry, 'shorttitle', $citeproc->{ titleshort });
    # do_set($entry, 'translator', $citeproc->{ translator });
    # do_set($entry, 'urldate', $citeproc->{ accessed });
    # do_set($entry, 'venue', $citeproc->{ 'event-place' });
    # do_set($entry, 'version', $citeproc->{ version });
    # do_set($entry, 'volume', $citeproc->{ volume });
    # do_set($entry, 'volumes', $citeproc->{ 'number-of-volumes' });

    $entry->set_key( 'doithing' );

    # http://fbennett.github.io/z2csl/ and
    # https://citeproc-js.readthedocs.io/en/latest/csl-json/markup.html

# PMCID* 	[standard] PubMed Central reference number
# PMID* 	[standard] PubMed reference number
# archive 	[standard] archive storing the item
# archive-place 	[standard] geographic location of the archive
# archive_location 	[standard] storage location within an archive (e.g. a box and folder number)
# authority 	[name] issuing or judicial authority (e.g. "USPTO" for a patent, "Fairfax Circuit Court" for a legal case)
# call-number 	[standard] call number (to locate the item in a library)
# collection-editor 	[name] editor of the collection holding the item (e.g. the series editor for a book)
# collection-number 	[number] number identifying the collection holding the item (e.g. the series number for a book)
# collection-title 	[standard] title of the collection holding the item (e.g. the series title for a book)
# composer 	[name] composer (e.g. of a musical score)
# container-title-short 	[standard] short/abbreviated form of "container-title" (also accessible through the "short" form of the "container-title" variable)
# contributor 	[mlz] non-standard variable that may be used for special purposes in some styles (e.g. to identify the author if interest in a multi-authored work in publications listings)
# genre 	[standard] class, type or genre of the item (e.g. "adventure" for an adventure movie, "PhD dissertation" for a PhD thesis)
# interviewer 	[name] interviewer (e.g. of an interview)
# issued 	[date] date the item was issued/published
# jurisdiction 	[standard] geographic scope of relevance (e.g. "US" for a US patent)
# keyword* 	[standard] keyword(s) or tag(s) attached to the item
# language 	[standard] Language code. Not intended for display purposes.
# locator* 	[standard] a cite-specific pinpointer within the item (e.g. a page number within a book, or a volume in a multi-volume work). Must be accompanied in the input data by a label indicating the locator type (see the Locators term list), which determines which term is rendered by cs:label when the "locator" variable is selected.
# medium 	[standard] medium description (e.g. "CD", "DVD", etc.)
# note 	[standard] (short) inline note giving additional item details (e.g. a concise summary or commentary)
# number 	[number] number identifying the item (e.g. a report number)
# number-of-pages 	[number] total number of pages of the cited item
# original-author* 	[name] ?
# original-date 	[date] (issue) date of the original version
# original-publisher* 	[standard] original publisher, for items that have been republished by a different publisher
# original-publisher-place* 	[standard] geographic location of the original publisher (e.g. "London, UK")
# original-title* 	[standard] title of the original version (e.g. "Война и мир", the untranslated Russian title of "War and Peace")
# page 	[standard] range of pages the item (e.g. a journal article) covers in a container (e.g. a journal issue)
# page-first* 	[standard] first page of the range of pages the item (e.g. a journal article) covers in a container (e.g. a journal issue)
# pending-number 	[mlz] number of an application or other executory document (e.g. a patent application)
# publication-date 	[mlz] date of secondary publication of offically issued material (e.g. the date of commercial publication of a court decision)
# publisher-place 	[standard] geographic location of the publisher
# rank-number* 	[mlz] number of position in a queue or hierarchy (e.g. a patent priority number)
# recipient 	[name] recipient (e.g. of a letter)
# references 	[standard] resources related to the procedural history of a legal case
# reviewed-author 	[name] author of the item reviewed by the current item
# reviewed-title* 	[standard] title of the item reviewed by the current item
# source 	[standard] from whence the item originates (e.g. a library catalog or database)
# submitted 	[date] date the item (e.g. a manuscript) has been submitted for publication

    return $entry;
}

sub do_title_split {
    my $data = shift;

    if (ref $data eq 'ARRAY') {
        $data = $data->[0];
    }

    return split /:/, $data, 2;
}

sub title_split {
    my ($title, $subtitle) = do_title_split(shift);
    return trim $title;
}

sub subtitle_split {
    my ($title, $subtitle) = do_title_split(shift);
    return undef unless defined $subtitle;
    return undef if $subtitle ~~ /^\s*$/;
    return trim $subtitle;
}

sub pages_endash {
    return join('–', split /-/, shift);
}

sub hyphen_isbn {
    my $data = shift;

    if (ref $data eq 'ARRAY') {
        $data = $data->[0];
    }

    my $isbn = Business::ISBN->new( $data )->as_isbn13;
    return $isbn->as_string;
}

sub author_behavior {
    my $authors_ref = shift;
    my @authors = map {
        # Come back to this
        $_->{given} . ' '. $_->{family}
    } @$authors_ref;
    my $str = join ' and ', @authors;
    return $str;
}

sub date_behavior {
    my $dates_ref = shift;
    my $date = $dates_ref->{ 'date-parts' }->[0];
    my @normalized_date = map { $_ = "0$_" if /^\d$/;  $_ } @$date;
    my $str = join '-', @normalized_date;
    return $str;
}

sub do_set {
    my ($entry, $field, $data) = @_;
    return unless defined $data;

    if (ref $data eq 'ARRAY') {
        $data = $data->[0];
    }

    $entry->set($field, $data);
}

sub do_set_with {
    my ($entry, $field, $f, $data) = @_;
    return unless defined $data;

    $data = $f->($data);

    return unless defined $data;

    $entry->set($field, $data);
}

sub citeproc_get_type {
    my $citeproc = shift or die;

    # The following are BibLaTeX types:
    #
    # article book mvbook inbook bookinbook suppbook booklet
    # collection mvcollection incollection suppcollection manual misc
    # online patent periodical suppperiodical proceedings
    # mvproceedings inproceedings reference mvreference inreference
    # report set thesis unpublished artwork audio commentary image
    # jurisdiction legislation legal letter movie music performance
    # review software standard video

    # https://aurimasv.github.io/z2csl/typeMap.xml
    my %typemap = (
        'article' => 'article',
        'article-journal' => 'article',
        'article-magazine' => 'article',
        'article-newspaper' => 'article',
        'bill' => 'legislation',
        'book' => 'book',
        'broadcast' => 'performance',
#        'chapter' => 'inbook',
        'chapter' => 'incollection',
        'classic' => 'book',
        'collection' => 'collection',
        'dataset' => 'misc',
        'document' => 'unpublished',
        'entry' => 'inreference',
        'entry-dictionary' => 'inreference',
        'entry-encyclopedia' => 'inreference',
        'event' => 'misc',
        'figure' => 'image',
        'graphic' => 'image',
        'hearing' => 'jurisdiction',
        'interview' => 'misc',
        'legal_case' => 'jurisdiction',
        'legislation' => 'legislation',
        'manuscript' => 'unpublished',
        'map' => 'artwork',
        'monograph' => 'book',
        'motion_picture' => 'video',
        'musical_score' => 'music',
        'pamphlet' => 'unpublished',
        'paper-conference' => 'inproceedings',
        'patent' => 'patent',
        'performance' => 'performance',
        'periodical' => 'periodical',
        'personal_communication' => 'unpublished',
        'post' => 'online',
        'post-weblog' => 'online',
        'regulation' => 'jurisdiction',
        'report' => 'report',
        'review' => 'review',
        'review-book' => 'review',
        'software' => 'software',
        'song' => 'music',
        'speech' => 'misc',
        'standard' => 'standard',
        'thesis' => 'thesis',
        'treaty' => 'legal',
        'webpage' => 'online'
    );

    return $typemap{ $citeproc->{type} } || 'misc';
}

# Main:

my $doi = $ARGV[0];
my $citeproc = doi_to_citeproc( $doi );
print Dumper( $citeproc );
my $entry = citeproc_to_biblatex( $citeproc );
say $entry->print_s();

