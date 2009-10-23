package TaskDBDriver;

use strict;
use warnings;

use FileHandle;
use Data::Dumper;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};

  bless ($self, $class);

  $self->{'db_file'} = shift;
  $self->{'db'} = {};

  $self->read_db();

  return $self;
}

#
# Read in task db and store in a hash
#
sub read_db {
  my $self = shift;

  my $fh = new FileHandle ($self->{'db_file'});

  die "Could not open task file '" . $self->{'db_file'} . "' : $!"
    unless ($fh->open($self->{'db_file'}));

  $self->{'db'}->{'sections'} = [];

  my $section;

  while (<$fh>) {
    chomp;

    if (my ($sect_hdr) = m/\s*(.*?)\s*:\s*$/) {
      if (defined $section) {
        push @{$self->{'db'}->{'sections'}}, $section;
      }
      $section = {};
      $section = {  'name'  => $sect_hdr,
                    'desc'  => "",
                    'tasks' => []
                  };
    }

    if (my ($sect_desc) = m/^\t+\s*(.*?)\s*$/) {
      $section->{'desc'} = $sect_desc;
    }

    if (my ($task_name, $all_tags) = m/\s*-\s+(.*?)\s+((@\w+\s*)+|\s*)$/xg) {
      push @{$section->{'tasks'}},
           {  'name' => $task_name,
              'done' => ($all_tags =~ m/\@done/) ? 1 : 0,
              'tags' => [ map { s/@//; $_ } split (/\s+/, $all_tags) ] };
    }
  }

  push @{$self->{'db'}->{'sections'}}, $section;

  $fh->close();
}

#
# Write out the database file as closely representing the actual
# text file. Indentation will be hard to maintain
#
sub write_db_text {
  my $self = shift;
  my $ret_str = "";

  foreach my $section (@{$self->{'db'}->{'sections'}}) {
    $ret_str .= "$section->{'name'}:\n";
    $ret_str .= "\t$section->{'desc'}\n";

    foreach my $task (@{$section->{'tasks'}}) {
      $ret_str .= "- $task->{'name'}";
      foreach my $tag (@{$task->{'tags'}}) {
        $ret_str .= " \@$tag";
      }
      $ret_str .= "\n";
    }
    $ret_str .= "\n";
  }

  return $ret_str;
}

#
# Write out html markup of the database. This can be used by a CGI
# script to display the data base on a browser
#
sub write_db_markup {
  my $self = shift;
  my $ret_str = "";

  $ret_str .= "<div class='task_db'>\n";

  foreach my $section (@{$self->{'db'}->{'sections'}}) {
    $ret_str .= "  <div class='section'><h2>$section->{'name'}</h2>\n";
    $ret_str .= "  <div class='section_desc'>$section->{'desc'}</div>\n";

    $ret_str .= "  <ul class='tasks'>\n";
    foreach my $task (@{$section->{'tasks'}}) {
      my $task_class = ($task->{'done'}) ? 'task_item_done' : 'task_item';
      $ret_str .= "    <li class='$task_class'>$task->{'name'}\n";
      foreach my $tag (@{$task->{'tags'}}) {
        $ret_str .= "        <span class='task_tag'>$tag</span>\n";
      }
      $ret_str .= "    </li>\n";
    }
    $ret_str .= "  </ul>\n";
    $ret_str .= "  </div>\n\n";
  }
  $ret_str .= "</div>\n";

  return $ret_str;
}

1;
