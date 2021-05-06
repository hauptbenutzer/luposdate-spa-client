'use strict';

var gulp = require('gulp');

// load plugins
var $ = require('gulp-load-plugins')();

var concat = require('gulp-concat');

var handleError = function (err) {
    new $.util.log(err);
    this.emit('end');
}

gulp.task('hjson', function () {
    return gulp.src(['app/config/*.hjson'])
        .pipe($.hjson({to: 'json'}))
        .pipe(gulp.dest('dist/config'));
});

gulp.task('styles', function () {
    return gulp.src('app/styles/main.scss')
        .pipe($.sass({errLogToConsole: true}))
        .pipe(gulp.dest('dist/styles'));
});

gulp.task('concatCSS', function(){	
  return gulp.src([
    "bower_components/foundation/css/foundation.css",
	"bower_components/codemirror/lib/codemirror.css",
	"bower_components/font-source-sans-pro/source-sans-pro.css",
	"bower_components/please-wait/build/please-wait.css",
	"bower_components/codemirror/addon/fold/foldgutter.css"
  ])
    .pipe(concat('vendor.css'))
    .pipe(gulp.dest('dist/styles/'));	
});

gulp.task('scripts', function () {
    return gulp.src('app/scripts/*.coffee')
        .pipe($.coffee({bare: true})).on('error', handleError)
        .pipe(gulp.dest('dist/scripts/'));
});

gulp.task('copyJS', function(){	
    return gulp.src('app/scripts/**/*.js')
        .pipe(gulp.dest('dist/scripts/'));
});

gulp.task('concatJS', function(){	
  return gulp.src(["bower_components/modernizr/modernizr.js",
 "bower_components/jquery/dist/jquery.js",
 "bower_components/fastclick/lib/fastclick.js",
 "bower_components/jquery.cookie/jquery.cookie.js",
 "bower_components/jquery-placeholder/jquery.placeholder.js",
 "bower_components/foundation/js/foundation.js",
 "bower_components/underscore/underscore.js",
 "bower_components/backbone/backbone.js",
 "bower_components/codemirror/lib/codemirror.js",
 "bower_components/x2js/xml2json.min.js",
 "bower_components/randomcolor/randomColor.js",
 "bower_components/uri.js/src/URI.js",
 "bower_components/uri.js/src/IPv6.js",
 "bower_components/uri.js/src/SecondLevelDomains.js",
 "bower_components/uri.js/src/punycode.js",
 "bower_components/uri.js/src/URITemplate.js",
 "bower_components/uri.js/src/jquery.URI.js",
 "bower_components/uri.js/src/URI.min.js",
 "bower_components/uri.js/src/jquery.URI.min.js",
 "bower_components/uri.js/src/URI.fragmentQuery.js",
 "bower_components/uri.js/src/URI.fragmentURI.js",
 "bower_components/codemirror/addon/edit/matchbrackets.js",
 "bower_components/codemirror/addon/edit/closebrackets.js",
 "bower_components/codemirror/mode/sparql/sparql.js",
 "bower_components/foundation/js/foundation/foundation.abide.js",
 "bower_components/foundation/js/foundation/foundation.accordion.js",
 "bower_components/foundation/js/foundation/foundation.alert.js",
 "bower_components/foundation/js/foundation/foundation.clearing.js",
 "bower_components/foundation/js/foundation/foundation.dropdown.js",
 "bower_components/foundation/js/foundation/foundation.equalizer.js",
 "bower_components/foundation/js/foundation/foundation.interchange.js",
 "bower_components/foundation/js/foundation/foundation.joyride.js",
 "bower_components/foundation/js/foundation/foundation.js",
 "bower_components/foundation/js/foundation/foundation.magellan.js",
 "bower_components/foundation/js/foundation/foundation.offcanvas.js",
 "bower_components/foundation/js/foundation/foundation.orbit.js",
 "bower_components/foundation/js/foundation/foundation.reveal.js",
 "bower_components/foundation/js/foundation/foundation.slider.js",
 "bower_components/foundation/js/foundation/foundation.tab.js",
 "bower_components/foundation/js/foundation/foundation.tooltip.js",
 "bower_components/foundation/js/foundation/foundation.topbar.js",
 "bower_components/please-wait/build/please-wait.js"])
    .pipe(concat('vendor.js'))
    .pipe(gulp.dest('dist/scripts/'));	
});

gulp.task('svg', function () {
    var config = {
        shape: {
            id: {
                separator: '-'
            }
        },
        mode: {
            symbol: {
                dest: 'sprites',
                sprite: 'svgs.svg'
            }
        }
    };
    return gulp.src('app/images/icons/*.svg')
        .pipe($.svgSprite(config))
        .pipe(gulp.dest('dist/images'));
});

gulp.task('JST', function () {
    return gulp.src('app/templates/**/*.html')
        .pipe($.jstConcat('jst.js', {
            renameKeys: ['^.*templates/(.*).html$', '$1']
        })).on('error', handleError)
        .pipe(gulp.dest('dist/scripts'))
})

gulp.task('html', gulp.series('styles', 'concatCSS', 'scripts', 'JST', 'copyJS', 'concatJS', 'hjson', function () {
    var jsFilter = $.filter('**/*.js');
    var cssFilter = $.filter('**/*.css');

    return gulp.src('app/*.html')
        .pipe(gulp.dest('dist'));
}));

gulp.task('resources', function () {
    return gulp.src('app/resources/**/*')
        .pipe(gulp.dest('dist/resources'));
});

gulp.task('images', function () {
    return gulp.src('app/images/**/*')
        .pipe(gulp.dest('dist/images'));
});

gulp.task('fonts', function () {
    var streamqueue = require('streamqueue');
    return streamqueue({objectMode: true},
        gulp.src('app/bower_components/font-source-sans-pro/{EOT,OTF,TTF,WOFF}/**/*.{eot,svg,ttf,woff,otf}')
    )
        .pipe(gulp.dest('dist/styles'));
});

gulp.task('clean', function () {
    return gulp.src(['dist'], {allowEmpty:true, read: false}).pipe($.clean());
});


gulp.task('build', gulp.series('html', 'svg', 'images', 'fonts', 'resources', function (done) {
    console.log('build done');
	done();
}));

gulp.task('default', gulp.series('clean', 'build', function (done) {
    console.log('done');
	done();
}));