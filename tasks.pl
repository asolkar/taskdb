#!/usr/bin/perl

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use strict;
use warnings;

use TaskDBDriver;
use FileHandle;

my $task_file = "/home/mahesh/.tasks";

my $q = new CGI;

print $q->header;

if ($q->param('q') eq 'edit') {
  show_tasks_form($q);
} elsif ($q->param('q') eq 'Save') {
  my $th = new FileHandle ('>' . $task_file);

  if (defined $th) {
    print $th $q->param('tasks_text');
    $th->close;
  } else {
    print "ERROR: Could not open $task_file to write: $!";
  }

  show_tasks($q);
} else {
  show_tasks($q);
}

# ---------------
# Functions
# ---------------
sub show_tasks {
  my $q = shift;

  my $tasks_db = new TaskDBDriver ($task_file);

  print $q->start_html( -title => 'Tasks',
                        -script => { -code => page_script() },
                        -style => { -code => page_style() } ),
        $q->start_div( {-id => "wrapper"} ),
        $q->h1('Tasks'),
        $q->a({-href => $q->url . "?q=edit", -style => 'text-align: center'}, "Edit"),
        " | ",
        $q->a({-href => "javascript:toggle_completed();", -style => 'text-align: center'}, "Toggle completed"),
        $tasks_db->write_db_markup(),
        $q->end_html;
}

sub show_tasks_form {
  my $q = shift;

  my $tasks_db = new TaskDBDriver ($task_file);

  print $q->start_html( -title => 'Tasks',
                        -style => { -code => page_style() } ),
        $q->start_div( {-id => "wrapper"} ),
        $q->h1('Tasks'),
        $q->start_form (-action => $q->url(),
                        -method => 'POST'),
        $q->textarea (-name => 'tasks_text',
                      -default => $tasks_db->write_db_text(),
                      -rows => 15,
                      -columns => 100),
        $q->br,
        $q->submit (-name => 'q',
                    -value => 'Save'),
        $q->reset(),
        $q->a({-href => $q->url, -style => 'text-align: center'}, "Cancel"),
        $q->end_form,
        $q->end_html;
}

sub page_style {
  return qq {
body {
  font-family : "Trebuchet MS", sans-serif;
  font-size : small;
  background-color : white;
}
h1 {
  border-bottom : 2px solid #cccccc;
  text-align : right;
  color : #888888;
  font-size : xx-large;
}
#wrapper {
  display : table;
  margin : 0 auto;
  padding : 10px 10px 10px 10px;
  width : 700px;
}
.task_db {
  padding-top : 7px;
  padding-bottom : 7px;
}
.section {
  border : thin solid #cccccc;
  padding : 0px 0px 0px 0px;
  margin-bottom : 10px;
}
.section h2 {
  padding : 2px 2px 2px 2px;
  margin : 0;
  background-color : #cccccc;
}
.section .section_desc {
  border : thin solid #eeeeee;
  padding : 3px 3px 3px 3px;
}
.section ul {
  margin : 3px 3px 3px 3px;
}
li.task_item, li.task_item_done {
  line-height : 2em;
}
li.task_item_done {
  color : #aaaaaa;
}
.task_tag {
  padding : 1px 1px 1px 1px;
}
li.task_item .task_tag {
  border : thin solid #aaaaff;
  background-color : #aaaaff;
}
li.task_item_done .task_tag {
  color : #aaaaaa;
  border : thin solid #eeeeee;
  background-color : #eeeeee;
}

  };
}

sub page_script {
  return qq {
function toggle_completed () {
  var done_tasks = document.getElementsByClassName ('task_item_done');

  for each (var task in done_tasks) {
    task.style.display = (task.style.display == 'none') ? 'list-item' : 'none';
  }
}
  };
}
