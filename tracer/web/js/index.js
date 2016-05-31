var svg = d3.select('svg');
var w = 1200;
var h = 720;

var mw = w / 3
var mh = 612 / 792 * mw

// offsets for floor maps
function floorX(n) { return n % 3 * w / 3 }
function floorY(n) { return Math.floor(n / 3) * mh }

// add the venue maps
function addfloor(n) {
  svg.append("image").attr("xlink:href", "maps/hs16w_" + n + "f.svg").attr("width", mw)
      .attr("height", mh)
      .attr("x", floorX(n))
      .attr("y", floorY(n))
      .attr("style", "opacity: 0.25")
}
for (i = 0; i < 5 ; i++ ) addfloor(i);

// put the pis on the map
function x(d) { return floorX(d.floor) + d.location.x * 792 / mw }
function y(d) { return floorY(d.floor) + d.location.y * 612 / mh }

d3.json("locations.json", function(e,j) {
  if (e) return console.warn(e);
  svg.selectAll("g.pi")
    .data(j).enter()
    .append("svg:circle").attr("r","4").attr("cx", x).attr("cy", y)

  function indexLocations(j) {
    var i = {};
    j.forEach(function(n) {
      i[n.device] = n;
    })
    return i;
  }
  doMainLoop(indexLocations(j))
})

function doMainLoop(locations) {
  function mapToLocation(i) {
    return locations[i.s]
  }

  getTrace('64-BC-0C-64-2E-45')

  function getTrace(mac) {
    d3.json("/traces/" + mac + "/b", function(e,j) {
      var t = j.Row[0].Cell.map(function(i) {
        return { rd: atob(i.column).substring(2), d: new Date(atob(i.column).substring(2) * 1000), s: atob(i['$']) }
      })
      var l = t.map(mapToLocation).filter(function(x) { return x} );

      svg.selectAll("g.trace")
        .data(l).enter()
        .append("svg:circle")
        .attr("r", "6")
        .attr('cx', x)
        .attr('cy', y)
        .attr('opacity','0.5')
        .attr('fill', 0x990000)

      p = [];
      for (var i = 1 ; i < l.length; ++i ) {
        console.log(i);
        p.push([l[i],l[i-1]])
      }

      function x1(d) {
        return floorX(d[0].floor) + d[0].location.x * 792 / mw
      }
      function x2(d) {
        return floorX(d[1].floor) + d[1].location.x * 792 / mw
      }
      function y1(d) {
        return floorY(d[0].floor) + d[0].location.y * 792 / mw
      }
      function y2(d) {
        return floorY(d[1].floor) + d[1].location.y * 792 / mw
      }

      function delay(d,i) {
        return i * 1000
      }
      function delayout() {
        return delay(args) + 1500
      }

      svg.selectAll("g.traceline").data(p).enter()
        .append("svg:line")
        .attr("x1", x1)
        .attr("x2", x2)
        .attr("y1", y1)
        .attr("y2", y2)
        .attr("marker-end", "url(#triangle)")
        .attr("stroke", "black")
        .attr("stroke-width","2")
        .attr("opacity", 0)
        .transition()
        .attr("opacity", 1)
        .duration(500)
        .delay(delay)
        .transition()
        .attr("opacity", 0)
        .duration(10000)
        .delay(delayout)
    })
  }

}

/*
<marker id="triangle"
      viewBox="0 0 10 10" refX="0" refY="5"
      markerUnits="strokeWidth"
      markerWidth="4" markerHeight="3"
      orient="auto">
      <path d="M 0 0 L 10 5 L 0 10 z" />
    </marker>*/

// get a trace from the hbase map, and replay


// heatmap by time of day
