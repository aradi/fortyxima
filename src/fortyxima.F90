module fortyxima
  m4_ifdef({WITH_FILESYS}, {use fortyxima_filesys})
  m4_ifdef({WITH_UNITTEST}, {use fortyxima_unittest})
  implicit none
end module fortyxima
