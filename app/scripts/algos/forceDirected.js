/**
 * Created by han on 03.03.15.
 */


function createForceDirectedGraph(container, data){

    var json = formatData(data);


    $(container + " svg").remove();

    var w = $(container).width() || 400,
        h = $(container).height() || 400,
        r = 10,
        fill = d3.scale.category20();

    //fixed first node on top
    json.nodes[0].fixed = 1;
    json.nodes[0].x = w/2;
    json.nodes[0].y = 50;

    var force = d3.layout.force()
        .charge(-180)
        .friction(0.9)
        .linkDistance(50)
        .size([w, h]);

    var svg = d3.select(container).append("svg:svg")
        .attr("width", w)
        .attr("height", h);

    var link = svg.selectAll("line")
        .data(json.links)
        .enter().append("svg:line");

    var node = svg.selectAll("circle")
        .data(json.nodes)
        .enter().append("svg:circle")
        .attr("class", "node")
        .attr("data-text", function(d) { return d.name || d.description})
        .attr("r", r - .75)
        .style("fill", function(d) { return fill(d.group); })
        .style("stroke", function(d) { return d3.rgb(fill(d.group)).darker(); })
        .call(force.drag);

    var text = svg.selectAll("text").data(json.nodes)
        .enter().append("svg:text")
        .attr("class", "nodeText")
        .attr("data-level", function (d) { return d.level })
        .attr("data-id", function (d) { return d.id })
        .attr("x", function(d) { return d.x; })
        .attr("y", function(d) { return (d.y); })
        .text(function(d) { return d.name || d.description; })
        .style("fill","#333")
        .call(force.drag);

    force
        .nodes(json.nodes)
        .links(json.links)
        .on("tick", tick)
        .start();

    function tick(e) {
        // Push sources up and targets down to form a weak tree.
        var k = 6 * e.alpha;
        json.links.forEach(function(d, i) {
            d.source.y -= k;
            d.target.y += k;
        });

        node.attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; });

        link.attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });

        text
            .attr("x", function (d) { return d.x + 11 })
            .attr("y", function (d) { return d.y + 5 });
    }

}

function formatData(data){
    var rawNodes = data.optimization.steps[0].operatorGraph.nodes;
    var rawLinks = data.optimization.steps[0].operatorGraph.edges;

    var linksArray = [];
    for(var key in rawLinks) {
        if(rawLinks.hasOwnProperty(key)) {
            var sourceId = getIndexKey(key, rawLinks);
            var targetId = getIndexValue(rawLinks[key][0], rawLinks);
            linksArray.push({"source" : sourceId, "target" : targetId, "value" : 1})
        }
    }

    console.log(linksArray);
   return {"nodes" : rawNodes, "links" : linksArray}
}

function getIndexKey (keyValue, data){
    var count = 0;
    for(var number in data) {
        if(data.hasOwnProperty(number)) {
            if(data[number] == keyValue) return count;
        }
        count++;
    }

    console.log("ARGH1" , keyValue, data)

    return false;
}

function getIndexValue(keyValue, data){
    var count = 0;
    for(var number in data) {
        if(data.hasOwnProperty(number)) {
            //if(number == keyValue) return count;




        }
        count++;
    }
    console.log("ARGH2" , keyValue, data)
    return false;
}
