/* System libraries */
const express = require("express");
const fs = require('fs');
const fsmonitor = require('fsmonitor');
const path = require('path');
const md5File = require('md5-file');
const recursiveReadDir = require("recursive-readdir");


/* Constants */
const ROOT_DIRECTORY = './testfolder/';
const MATCH_CONFIG = {
  matches: function(relpath) {
    return relpath.match(/\.lua$/i) !== null;
  },
  excludes: function(relpath) {
    return relpath.match(/^\.git$/i) !== null;
  },
};


/* App */
const util = require('./lib/util.js');

const app = express()
app.use(require('body-parser').json());
app.longpoll = require("express-longpoll")(app);

function validatePathMiddle(req, res, next)
{
  let filepath = req.body.filepath;

  if (!filepath) {
    console.warn('Failed request, no file path');
    return res.status(400).json({
      error: 'No filepath'
    });
  }

  if (!util.isValid(filepath)) {
    console.warn('Failed request, bad file path,', filepath);
    return res.status(422).json({
      error: 'Bad file path'
    });
  }

  req.filepath = path.resolve(ROOT_DIRECTORY, filepath) + '.lua';
  return next();
};


/* Routing */
app.post('/filechanged', validatePathMiddle, function(req, res) {
  let filepath = req.body.filepath;
  let content = req.body.content;


  if (!content) {
    res.status(400).json({
      error: 'No content'
    });
    return;
  }

  // let fileName = path;
  // fs.writeFile(file, content);
})

app.get('/', function(req, res) {
  res.send('Hello World');
});

app.post('/files/source', validatePathMiddle, function(req, res) {
  console.assert(req.filepath, "expected filepath");

  let content = fs.readFile(req.filepath, 'utf8', function(err, data) {
    if (err) {
      console.error(err);
      return res.status(500).json({
        error: err,
      });
    }

    return res.send(data);
  });
});

app.get('/files', function(req, res) {
  recursiveReadDir(ROOT_DIRECTORY, function(err, items) {
    if (err) {
      return req.status(500).json({
        error: err,
      });
    }

    /* Parse items to include only items wanted */
    let newItems = {};
    for (let i in items) {
      let basepath = items[i];
      let relpath = path.relative(ROOT_DIRECTORY, basepath);
      let totalpath = path.resolve(basepath);

      /* Strip .lua */
      if (MATCH_CONFIG.matches(relpath) && !MATCH_CONFIG.excludes(relpath))
      {
        // Could make this a promise.all()
        let hash = md5File.sync(path.join(ROOT_DIRECTORY, relpath));
        newItems[util.toLuaPath(relpath)] = hash;
      } else {
        console.warn('bad path', relpath);
      }
    }

    return res.json(newItems);
  })
})

// /* Check */
// app.post('/hashes/', function(req, res) {
//   let fileToHash = req.body.fileToHash;

//   if (!fileToHash) {
//     res.status(400).json({
//       error: 'No fileToHash';
//     });
//     return;
//   }

//   let different = [];
//   for (let path in fileToHash) {
//     if (!util.isValid(path)) {
//       res.status(422).json({
//         error: 'Bad file path'
//       });
//       return;
//     }

//     let hash = fileToHash[path];
//     let systemHash = md5File(path);

//     if (hash != systemHash) {
//       different[path] = systemHash;
//     }
//   }
// });

let watcher = fsmonitor.watch(ROOT_DIRECTORY, MATCH_CONFIG);

app.longpoll.create('/filechanged/poll', function(req, res, next) {
  // console.log('New listener to poll'); 
  next();
});



function fixFilePaths(paths) {
  let newPaths = {};

  for (let i in paths) {
    let relpath = paths[i];
    let hash = md5File.sync(path.join(ROOT_DIRECTORY, relpath));
    newPaths[util.toLuaPath(relpath)] = hash;
  }

  if (!newPaths) {
    return undefined;
  }

  return newPaths;
}
watcher.on('change', function(changes) {
  let changesClean = {};

  changesClean['ModifiedFiles'] = fixFilePaths(changes['modifiedFiles']);
  console.log(changesClean);

  app.longpoll.publish('/filechanged/poll', changesClean);
});

/* Load server */
app.listen(3000, () => console.log('Example app listening on port 3000!'))