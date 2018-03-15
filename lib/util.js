const path = require('path');


module.exports.isValid = function(filepath) {
  if (path.posix.isAbsolute(filepath)) {
    console.warn('Bad path, absolute. "' + filepath + '"');
    return false;
  }

  /* Avoid some hacky stuff */
  if (filepath.includes("..")) {
    console.warn('Bad path, has .. "' + filepath + '"');
    return false;
  }

  return true;
}

module.exports.toLuaPath = function (relpath) {
  return path.posix.join(path.dirname(relpath), path.basename(relpath, '.lua'))
}
// function module.exports.systemHash(directory) {
//   return path.isAbsolute(filepath);
// }

