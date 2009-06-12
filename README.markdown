Score 1.0
---------

Everybody has a way of generating csound scores from scripting languages, it seems.

This one's mine; following the classic 'framework' pattern, it takes into
account the sorts of things I do over and over again.

Interested in knowing how it works? Try any of the following:

- have a look at the simple-example.pl script
- perldoc any of the *.pm in lib/
- look at the tests in t

To run the tests, "prove -Ilib t/" or "perl Makefile.PL; make test".

*Note on naming:* Maybe 'Score' is too generic a name; maybe it should've been
something like Csound::Score. But I'm lazy and don't feel like typing all that
every time I want to use it, so: tough (also: maybe I'll rename it later; this
is really just a way for me to get used to playing around with git and github).

Dan Friedman

Toronto, June, 2009
