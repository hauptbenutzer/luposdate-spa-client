/**
 * Created by Hannes on 02.03.15.
 */


function createVerticalTree(data){
    $('#luposgraph svg').remove();
    h = 500;
    w = 800;

    // ************** Generate the tree diagram *****************
//    var margin = {top: 40, right: 120, bottom: 20, left: 120},
//        width = 960 - margin.right - margin.left,
//        height = 500 - margin.top - margin.bottom;

    var i = 0;
    var tree = d3.layout.tree().size([h, w]);
    var zoomListener = d3.behavior.zoom().scaleExtent([0.1, 3]).on("zoom", redraw);

    var svg = d3.select("#luposgraph")
        .append("svg:svg")
        .attr("id","luposgraph-vertical-tree")
        .attr("width", w)
        .attr("height", h)
        .attr("pointer-events", "all")
//        .call(d3.behavior.zoom().on("zoom", redraw))
        .call(zoomListener)
        .append('svg:g').attr("class","hiho2")

    function redraw() {
        svg.attr("transform", "translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")");
    }




    root = data.AST;
    update(root);

    function update(source) {
        console.log("update",source);
// Compute the new tree layout.
        var nodes = tree.nodes(root).reverse(),
            links = tree.links(nodes);
// Normalize for fixed-depth.
        nodes.forEach(function(d) { d.y = d.depth * 100; });
// Declare the nodes…
        var node = svg.selectAll("g.node")
            .data(nodes, function(d) { return d.id || (d.id = ++i); });
// Enter the nodes.
        var nodeEnter = node.enter().append("g")
            .attr("class", "node")
            .attr("transform", function(d) {
                return "translate(" + d.x + "," + d.y + ")"; })
            .attr("data-text", function(d) { return d.description});
        nodeEnter.append("circle")
            .attr("r", 10)
            .style("fill", "#fff")
        nodeEnter.append("text")
            .attr("y", function(d) {
                return d.children || d._children ? -18 : 18; })
            .attr("dy", ".35em")
            .attr("text-anchor", "middle")
            .text(function(d) { return d.description.split("\n")[0]; })
            .style("fill-opacity", 1);
// Declare the links…
        var link = svg.selectAll("path.link").data(links, function(d) { return d.target.id; });
// Enter the links.
        link.enter().insert("path", "g")
            .attr("id", function(d){
                var source = d.source.id;
                var target = d.target.id;
                return "path_"+source+"_"+target;
            })
            .attr("class", "link")
            .attr("d",function(d){return "M "+d.source.x+" "+d.source.y+" L"+d.target.x+" "+d.target.y;})
//                .attr("d", diagonal);

        var linkText = svg.selectAll("text.linktext").data(links, function(d) { return d.target.id; });

        linkText.enter().insert("text", "g")
            .attr("class","linktext")
            .attr("id",function(d){ console.log(d);return (typeof d.source.id == "undefined") ? "label_"+d.source +"_"+ d.target : "label_"+d.source.id+"_"+ d.target.id})
            .attr("text-anchor", "middle")
            .style("text-anchor", "middle")
            .style("font-size","10px")
            .style("fill","#888")
            .append("textPath")
            .attr("xlink:href",function(d){ return (typeof d.source.id == "undefined") ? "#path_"+d.source+"_"+ d.target : "#path_"+d.source.id+"_"+ d.target.id;})
            .attr("class","labelpath")
            .attr("text-anchor", "middle")
            .style("text-anchor", "middle")
            .attr("startOffset", "47%")

            .text(function(d){return d.source.type + " --> "+ d.target.type;});


        centerNode();
    }
    function centerNode() {
        scale = zoomListener.scale();
        x = w / 4;
        y = 40;
        d3.select('g').transition()
            .duration(1000)
            .attr("transform", "translate(" + x + "," + y + ")scale(" + scale + ")");
        zoomListener.scale(scale);
        zoomListener.translate([x, y]);
    }


}
