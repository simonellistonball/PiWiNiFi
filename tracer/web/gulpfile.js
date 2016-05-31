// Include gulp
var gulp = require('gulp');

var url = require('url');
//var proxy = require('proxy-middleware');
var browserSync = require('browser-sync');

var paths =  {
    css: ['./**/*.css', '!./node_modules/**/*']
};

var proxyMiddleware = require('http-proxy-middleware');

// browser-sync task for starting the server.
gulp.task('browser-sync', function() {
    var prox = proxyMiddleware('/traces', { target: 'http://hs16w01.cloud.hortonworks.com:8000/traces', prependPath: false })
    browserSync({
        open: true,
        port: 3000,
        server: {
            baseDir: "./",
            middleware: [function(req,res, next) {
              if (req.url.startsWith('/api')) {
                req.headers['Accept'] = 'application/json'                
              }
              next()
            }, prox]
        }
    });
});

// Stream the style changes to the page
gulp.task('reload-css', function() {
    gulp.src(paths.css)
        .pipe(browserSync.reload({stream: true}));
});

// Watch Files For Changes
gulp.task('watch', function() {
    gulp.watch(paths.css, ['reload-css']);
});
