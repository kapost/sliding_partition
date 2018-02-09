# v0.3.1 (2018-02-09)
- Fixed a major bug in the code when using a month partition interval.
  For short months, like February, the generated partitions skipped over that month (Feb)
  resulting in that table being dropped because it was not part of the table collection.
  This only occurred at the start of a short month.
 
# v0.1.0 (2016-08-30)

- Initial version.
