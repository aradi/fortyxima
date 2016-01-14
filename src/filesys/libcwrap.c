#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <string.h>
#include <unistd.h>

/** Initial size for path names. */
const size_t initsize = 1024;

/** Maximum size for path names. */
const size_t maxsize = 16384;


/** Delivers the file name of the next entry within a directory.
 *
 *  \details Delivers a string to the next entry within a directory. The
 *  entries '.' and '..' are filtered out.
 *
 *  \param dp  Directory descriptor.
 *  \return Pointer to the name of the next entry or NULL if any error occured.
 *      It should be deallocated by the caller.
 */
char *fortyxima_filesys_nextdirentry_name(DIR *dp)
{
  struct dirent dent;
  struct dirent *result;
  char *buffer;
  int status;

  if (dp != NULL) {
    while (1) {
      status = readdir_r(dp, &dent, &result);
      if (status || result != &dent) {
	break;
      }
      if (strcmp(dent.d_name, ".") && strcmp(dent.d_name, "..")) {
	buffer = (char *) malloc(sizeof(char) * (strlen(dent.d_name) + 1));
	if (buffer != NULL) {
	  strcpy(buffer, dent.d_name);
	  return buffer;
	}
	else {
	  break;
	}
      }
    }
  }
  return NULL;
}


/** Returns the name field of a directory entry.
 *  \param direntry  Directory entry descriptor.
 *  \return Pointer to d_name field of the descriptor.
 */
char *fortyxima_filesys_direntry_name(struct dirent *direntry)
{
  if (direntry != NULL) {
    return direntry->d_name;
  }
  else {
    return NULL;
  }
}  


/** Decides whether a given file name is a directory.
 *  \param fname  File name.
 *  \return 1 if file exists and is a directory, 0 otherwise.
 */
int fortyxima_filesys_isdir(const char *fname)
{
  struct stat statbuf;
  
  if (stat(fname, &statbuf)) {
    return 0;
  }
  else {
    return S_ISDIR(statbuf.st_mode);
  }
}


/** Decides whether a given file name is a symbolic link.
 *  \param fname  File name.
 *  \return 1 if file exists and is a symlink, 0 otherwise.
 */
int fortyxima_filesys_islink(const char *fname)
{
  struct stat statbuf;
  
  if (lstat(fname, &statbuf)) {
    return 0;
  }
  else {
    return S_ISLNK(statbuf.st_mode);
  }
}


/** Checks, whether a given file exists.
 *  \param fname  File name.
 *  \return 1 if file exists, 0 otherwise.
 */
int fortyxima_filesys_file_exists(const char *fname)
{
  struct stat statbuf;

  return !stat(fname, &statbuf);
}


/** Returns the size of a file.
 *  \param fname  File name.
 *  \return  Size of the file converted to size_t. If the file status can't
 *      be determined, the return value is -1. If the file size can't be
 *      converted to size_t, -2 is returned.
 *  
 */
size_t fortyxima_filesys_filesize(const char *fname)
{
  struct stat statbuf;
  size_t fsize;
  
  if (stat(fname, &statbuf)) {
    return -1;
  }
  fsize = (size_t) statbuf.st_size;
  if ((off_t) fsize == statbuf.st_size) {
    return fsize;
  }
  else {
    return -2;
  }
}


/** Creates a directory with all possible permitions (except those in umask).
 *  \param dirname  Name of the directory.
 *  \return Status code of the mkdir system call.
 */
int fortyxima_filesys_makedir(const char *dirname)
{
  return mkdir(dirname, S_IRWXU | S_IRWXG | S_IRWXO);
}


/** Helper routine for fortyxima_filesys_makedir_parent. 
 * Should be able also to handle paths containing './', '../' and '//'
 */
int _fortyxima_filesys_makedir_parent(const char *dirname, int dnamelen)
{
  char *newdirname;
  struct stat statbuf;
  int status, ii;

  status = stat(dirname, &statbuf);
  /* File does not exist. */
  if (status) {
    for (ii = dnamelen - 1; ii > 0 && dirname[ii] != '/'; ii--) ;
    /* If directory has parent directory try to create that one. */
    if (ii) {
      status = 0;
      newdirname = (char *) malloc(sizeof(char) * (ii + 1));
      strncpy(newdirname, dirname, ii);
      newdirname[ii] = '\0';
      status = _fortyxima_filesys_makedir_parent(newdirname, ii);
      free(newdirname);
      if (status) {
	return status;
      }
      else {
	status = stat(dirname, &statbuf);
      }
    }
  }
  /* File still does not exist yet */
  if (status) {
    return fortyxima_filesys_makedir(dirname);
  }
  /* File exists and is a directory. */
  else if (S_ISDIR(statbuf.st_mode)) {
    return 0;
  }
  /* File exists but is not a directory. */
  else {
    return -1;
  }
}


/** Creates a directory and if necessary its parents.
 *  \param dirname Name of the directory.
 *  \return 0 on success, status code of the mkdir call or -1 otherwise.
 */
int fortyxima_filesys_makedir_parent(const char *dirname)
{
  int dnamelen;
  char *newdirname;
  int status;

  dnamelen = strlen(dirname);
  if (dirname[dnamelen-1] == '/') {
    newdirname = (char *) malloc(sizeof(char) * dnamelen);
    dnamelen--;
    strncpy(newdirname, dirname, dnamelen);
    newdirname[dnamelen] = '\0';
    status = _fortyxima_filesys_makedir_parent(newdirname, dnamelen);
    free(newdirname);
  }
  else {
    status = _fortyxima_filesys_makedir_parent(dirname, dnamelen);
  }
  return status;
}


/** Recursively deletes an entry in the file system.
 * \param fname  File name.
 * \return 0 if recursive delete was successful, or some error codes otherwise.
 */
int fortyxima_filesys_rmtree(const char *fname)
{
  DIR *dp;
  struct dirent *ep;
  struct stat statbuf;
  char *newfname;
  int status;

  status = lstat(fname, &statbuf);
  if (status) {
    return -1;
  }
  if (S_ISDIR(statbuf.st_mode)) {
    dp = opendir(fname);
    if (dp != NULL) {
      while ((ep = readdir(dp))) {
	if ((!strcmp(ep->d_name, ".")) || (!strcmp(ep->d_name, ".."))) {
	  continue;
	}
	newfname = (char *) 
	  malloc(sizeof(char) * (strlen(fname) + strlen(ep->d_name) + 2));
	strcpy(newfname, fname);
	strcat(newfname, "/");
	strcat(newfname, ep->d_name);
	status = fortyxima_filesys_rmtree(newfname);
	free(newfname);
	if (status) {
	  return status;
	}
      }
    }
    else {
      status = -2;
    }
    closedir(dp);
    status = rmdir(fname);
    return status;
  }
  else {
    status = unlink(fname);
    return status;
  }
}


/** Returning working directory name with dynamic allocation as in glibc.
 *  \return Name of the working directory or NULL if any error happened. String
 *      should be deallocated by the caller.
 */
char *fortyxima_filesys_getcwd()
{
  size_t size = initsize;
  char *buffer;
     
  while (size <= maxsize) {
    buffer = (char *) malloc(size * sizeof(char));
    if (buffer == NULL) {
      break;
    }
    else if (getcwd(buffer, size) == buffer) {
      return buffer;
    }
    else {
      free(buffer);
      size *= 2;
    }
  }
  return NULL;
}


/** Frees a character string.
 *  \param cptr  Pointer to the character array.
 */
void fortyxima_filesys_freestring(char **cptr)
{
  if (*cptr != NULL) {
    free(*cptr);
  }
  *cptr = NULL;
}


/** Creates a copy of a character string
 *  \param orig Original string.
 *  \return A copy of the string.
 */
char *fortyxima_filesys_copystring(const char *origstr)
{
  size_t size;
  char *newstr;
  
  size = strlen(origstr);
  newstr = (char *) malloc(sizeof(char) * (size + 1));
  if (newstr != NULL) {
    return strcpy(newstr, origstr);
  }
  else {
    return NULL;
  }
}


/** Calls the libc readlink function with dynamic memory allocation.
 *  \param fname  Name of the link to resolve.
 *  \return Pointer to the resolved name or NULL if error occured. The string
 *      should be deallocated by the caller.
 */
char *fortyxima_filesys_readlink(const char *fname)
{
  size_t size = initsize;
  char *buffer;
  int nchar;
          
  while (size <= maxsize) {
    buffer = (char *) malloc(size * sizeof(char));
    if (buffer == NULL) {
      break;
    }
    nchar = readlink(fname, buffer, size);
    if (nchar < 0) {
      free(buffer);
      break;
    }
    else if (nchar < size - 1) {
      buffer[nchar] = '\0';
      return buffer;
    }
    else {
      free(buffer);
      size *= 2;
    }
  }
  return NULL;
}
