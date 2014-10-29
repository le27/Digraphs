#############################################################################
##
#W  oper.gi
#Y  Copyright (C) 2014                                   James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

# graph algorithms

#

InstallMethod(MultidigraphEdgeUnion, "for digraphs",
[IsDigraph, IsDigraph],
function(graph1, graph2)
  local m, n, outm, outn, out, i;

  if DigraphNrVertices(graph1) > DigraphNrVertices(graph2) then 
    m := DigraphNrVertices(graph2); # smaller graph
    n := DigraphNrVertices(graph1);        
    outm := OutNeighbours(graph2);  # out neighbours of smaller graph
    outn := OutNeighbours(graph1);
  else
    m := DigraphNrVertices(graph1);
    n := DigraphNrVertices(graph2);
    outm := OutNeighbours(graph1);
    outn := OutNeighbours(graph2);
  fi;

  out := EmptyPlist(n);

  for i in [ 1 .. m ] do 
    out[i] := Concatenation(outm[i], outn[i]);
  od;

  for i in [ m + 1 .. n ] do 
    out[i] := ShallowCopy(outn[i]);
  od;

  return DigraphNC(out);
end);

#

InstallMethod(DigraphFloydWarshall, "for a digraph",
[IsDigraph, IsFunction, IsObject, IsObject],
function(graph, func, nopath, edge)
  local vertices, n, m, dist, out, i, j, k;

  vertices := DigraphVertices(graph);
  n := DigraphNrVertices(graph);
  dist := EmptyPlist(n);

  for i in vertices do
    dist[i] := EmptyPlist(n);
    for j in vertices do 
      dist[i][j] := nopath;
    od;
  od;
  
  if HasDigraphSource(graph) then 
    m := Length(DigraphSource(graph));
    for i in [ 1 .. m ] do
      dist[ DigraphSource(graph)[i] ][ DigraphRange(graph)[i] ] := edge;
    od;
  else
    out := OutNeighbours(graph);
    for i in vertices do 
      for j in out[i] do 
        dist[i][j] := edge;
      od;
    od;
  fi;
  
  for k in vertices do
    for i in vertices do
      for j in vertices do
        func(dist, i, j, k);
      od;
    od;
  od;

  return dist;
end);

#

InstallMethod(DigraphReverse, "for a digraph with source",
[IsDigraph and HasDigraphSource],
function(graph)
  local source, range;

    source := ShallowCopy(DigraphRange(graph));
    range := Permuted(DigraphSource(graph), Sortex(source));

    return DigraphNC(rec( source:=source, 
                                range:=range,
                                nrvertices:=DigraphNrVertices(graph)));
end);

#

InstallMethod(DigraphReverse, "for a digraph by adjacency",
[IsDigraph and HasOutNeighbours],
function(graph)
  local old, new, i, j;

  old := OutNeighbours(graph);
  new := List(DigraphVertices(graph), x -> []);

  for i in DigraphVertices(graph) do 
    for j in old[i] do 
      Add(new[j], i);
    od;
  od;

  return DigraphNC(new);
end);

#

InstallMethod(DigraphReverseEdges, "for a digraph and an edge",
[IsDigraph and HasDigraphSource, IsRectangularTable],
function(digraph, edges)
  local source, range, i;

  if IsMultiDigraph(digraph) then
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the first argument <digraph> must not be a multigraph,");
    return;
  fi;

  if not IsPosInt(edges[1][1]) or 
    not ForAll(edges, x -> IsDigraphEdge(digraph, x)) then
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the second argument <edges> must be a list of edge of <digraph>,");
    return;
  fi;
 
  source := ShallowCopy(DigraphSource(digraph));
  range := ShallowCopy(DigraphRange(digraph));

  Sort(edges); 
  for i in [ 1 .. Length(source) ] do
    if [source[i], range[i]] in edges then 
      # swap source[ i] and range[i]
      source[i] := range[i] + source[i]; 
      range[i] := source[i] - range[i];
      source[i] := source[i] - range[i];
    fi;
  od;

  range := Permuted(range, Sortex(source));
  return DigraphNC(rec( source:=source, 
                        range:=range,
                        nrvertices:=DigraphNrVertices(digraph)));
end);

#

InstallMethod(DigraphReverseEdges, "for a digraph and an edge",
[IsDigraph and HasOutNeighbours, IsRectangularTable],
function(digraph, edges)
  local current, nredges, out, new, i;

  if IsMultiDigraph(digraph) then
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the first argument <digraph> must not be a multigraph,");
    return;
  fi;

  if not IsPosInt(edges[1][1]) or 
    not ForAll(edges, x -> IsDigraphEdge(digraph, x)) then
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the second argument <edges> must be a list of edge of <digraph>,");
    return;
  fi;
 
  Sort(edges);
  current := 1;


  nredges := Length(edges); 
  out := OutNeighbours(digraph);
  new := [];
  for i in [ 1 .. Length(DigraphVertices(digraph)) ] do
    new[i] := ShallowCopy(out[i]);
    while current <= nredges and  edges[current][1]  = i do
      Remove(new[i], Position(new[i], edges[current][2]));
      current := current + 1;
    od;
  od;

  for i in [ 1 .. nredges ]  do
    Add(new[edges[i][2]], edges[i][1]);
  od;

  return DigraphNC(new);
end);

#

# can we use IsListOf...
InstallMethod(DigraphReverseEdges, "for a digraph and an edge",
[IsDigraph and HasDigraphSource, IsList], 1,
function(digraph, edges)
  local nredges, source, range, i; 

  if IsMultiDigraph(digraph) then
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the first argument <digraph> must not be a multigraph,");
    return;
  fi;
  
  if Length(edges) = 0 then
    return digraph;
  fi;

  nredges := DigraphNrEdges(digraph);
  if not IsPosInt(edges[1]) or 
    not IsHomogeneousList(edges) or
    not ForAll( edges, x -> x <= nredges) then
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the second argument <edges> must be a list of edge of <digraph>,");
    return;
  fi;
 
  source := ShallowCopy(DigraphSource(digraph));
  range := ShallowCopy(DigraphRange(digraph));
  
  for i in edges do
    # swap source[i] and range[i]
    source[i] := range[i] + source[i]; 
    range[i] := source[i] - range[i];
    source[i] := source[i] - range[i];
  od;

  range := Permuted(range, Sortex(source));
  return DigraphNC(rec( source:=source, 
                        range:=range,
                        nrvertices:=DigraphNrVertices(digraph)));
end);

#
InstallMethod(DigraphReverseEdges, "for a digraph and an edge",
[IsDigraph and HasOutNeighbours, IsList],
function(digraph, edges)
  local nredges, current, out, new, pos_l, pos_h, toadd, pos, temp, i, edge;

  if IsMultiDigraph(digraph) then
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the first argument <digraph> must not be a multigraph,");
    return;
  fi;

  if Length(edges) = 0 then
    return digraph;
  fi;
  
  nredges := DigraphNrEdges(digraph);
  if not IsPosInt(edges[1]) or 
    not IsHomogeneousList(edges) or
    not ForAll(edges, x -> x <= nredges) then 
    Error("Digraphs: DigraphReverseEdges: usage,\n",
    "the second argument <edge> must be a list of edge of <digraph>,");
    return;
  fi;

  Sort(edges); 
  current := edges[1];
  out := OutNeighbours(digraph);  
  new := [];
  pos_l := 0; 
  pos_h := 0;

  toadd := [];
  pos := 1;
  for i in [ 1 .. Length(DigraphVertices(digraph)) ] do
    pos_h := pos_h + Length(out[i]);
    new[i] := ShallowCopy(out[i]);
    while pos_l < current and current <= pos_h do
      temp := current - pos_l;
      toadd[pos] := [ i, new[i][temp]];
      pos := pos + 1;
      Unbind(new[i][temp]); 
      if IsBound(edges[pos]) then
	current := edges[pos];
      else
	break;
      fi;
    od;
    new[i] := Flat(new[i]);
    pos_l := pos_l + Length(out[i]);
  od;

  for edge in toadd do
    Add(new[edge[2]], edge[1]);
  od;

  return DigraphNC(new);
end);

#

InstallMethod(DigraphReverseEdge, "for a digraph and an edge",
[IsDigraph, IsList],
function(digraph, edge)
  return DigraphReverseEdges(digraph, [edge]);
end);

#

InstallMethod(DigraphReverseEdge, "for a digraph and an edge",
[IsDigraph, IsPosInt],
function(digraph, edge)
  return DigraphReverseEdges(digraph, [edge]);
end);

#

InstallMethod(DigraphRemoveLoops, "for a digraph with source",
[IsDigraph and HasDigraphSource],
function(graph)
  local source, range, newsource, newrange, nr, out, i;

  source := DigraphSource(graph);
  range := DigraphRange(graph);

  newsource := [];
  newrange := [];
  nr := 0;

  for i in [ 1 .. Length(source) ] do
    if range[i] <> source[i] then
      nr := nr + 1;
      newrange[nr] := range[i];
      newsource[nr] := source[i];
    fi;
  od;

  out := DigraphNC(rec( source := newsource, range := newrange,
                        nrvertices := DigraphNrVertices(graph) ) );
  SetDigraphHasLoops(out, false);
  return out;
end);

InstallMethod(DigraphRemoveLoops, "for a digraph by adjacency",
[IsDigraph and HasOutNeighbours],
function(graph)
  local old, new, nr, out, i, j;
  
  old := OutNeighbours(graph);
  new := [];

  for i in DigraphVertices(graph) do 
    new[i] := []; 
    nr := 0;
    for j in old[i] do 
      if i <> j then 
        nr := nr + 1;
        new[i][nr] := j;
      fi;
    od;
  od;

  out := DigraphNC(new);
  SetDigraphHasLoops(out, false);
  return out;
end);

#

InstallMethod(DigraphRemoveEdges, "for a digraph and a list",
[IsDigraph, IsList],
function(graph, edges)
  local range, nrvertices, source, newsource, newrange, pos, i;

  if Length(edges) > 0 and IsPosInt(edges[1]) then # remove edges by index
    edges := Difference( [ 1 .. Length(DigraphSource(graph)) ], edges );

    return DigraphNC(rec(
      source     := DigraphSource(graph){edges},
      range      := DigraphRange(graph){edges},
      nrvertices := DigraphNrVertices(graph)));
  else
    if IsMultiDigraph(graph) then
      Error("Digraphs: DigraphRemoveEdges: usage,\n",
      "the first argument <graph> must not have multiple edges\n",
      "when the second argument <edges> is a list of edges,");
      return;
    fi;
    source := DigraphSource(graph);;
    range := DigraphRange(graph);;
    newsource := [ ];
    newrange := [ ];

    for i in [ 1 .. Length(source) ] do
      pos := Position(edges, [ source[i], range[i] ]); 
      if pos = fail then
        Add(newrange, range[i]);
        Add(newsource, source[i]);
      else 
        Remove(edges, pos);
      fi;
    od;

    return DigraphNC(rec( source := newsource, range := newrange,
                          nrvertices := DigraphNrVertices(graph) ) );
  fi;
end);

#

InstallMethod(DigraphAddEdge, "for a digraph and an edge",
[IsDigraph, IsList],
function(digraph, edge)
  local verts;

  verts := DigraphVertices(digraph);
  if Length(edge) <> 2
    or not IsPosInt(edge[1])
    or not IsPosInt(edge[2])
    or not edge[1] in verts
    or not edge[2] in verts then
    Error("Digraphs: DigraphAddEdge: usage,\n",
          "the second argument <edge> must be a pair of vertices of ",
          "<digraph>,");
    return;
  fi;

  return DigraphAddEdgesNC(digraph, [ edge ]);
end);

InstallMethod(DigraphAddEdges, "for a digraph and a list",
[IsDigraph, IsList],
function(digraph, edges)
  local vertices, newsource, newrange, m, edge;

  if not IsEmpty(edges) and
   (not IsList(edges[1])
    or not Length(edges[1]) = 2 
    or not IsPosInt(edges[1][1]) 
    or not IsRectangularTable(edges)) then
    Error("Digraphs: DigraphAddEdges: usage,\n",
          "the second argument <edges> must be a list of pairs of vertices\n",
          "of the first argument <digraph>,");
    return;
  fi;

  vertices := DigraphVertices(digraph);
  for edge in edges do
    if not (edge[1] in vertices and edge[2] in vertices) then
      Error("Digraphs: DigraphAddEdges: usage,\n",
          "the second argument <edges> must be a list of pairs of vertices\n",
          "of the first argument <digraph>,");
      return;
    fi;
  od;

  return DigraphAddEdgesNC(digraph, edges);
end);

InstallMethod(DigraphAddEdgesNC, "for a digraph with range and a list",
[IsDigraph and HasDigraphRange, IsList], 1,
function(digraph, edges)
  local newsource, newrange, m, edge;

  newsource := ShallowCopy(DigraphSource(digraph));
  newrange  := ShallowCopy(DigraphRange(digraph));
  m := Length(newsource);
  for edge in edges do
    m := m + 1;
    newsource[m] := edge[1];
    newrange[m] := edge[2];
  od;

  newrange := Permuted(newrange, Sortex(newsource));
  return DigraphNC(rec( source     := newsource,
                        range      := newrange,
                        nrvertices := DigraphNrVertices(digraph) ) );
end);

InstallMethod(DigraphAddEdgesNC, "for a digraph with out-neighbours and a list",
[IsDigraph and HasOutNeighbours, IsList],
function(digraph, edges)
  local out, new, verts, edge;

  out := OutNeighbours(digraph);
  new := List( out, ShallowCopy );
  verts := DigraphVertices( digraph );
  for edge in edges do
    Add( new[ edge[1] ], edge[2] );
  od;
  return DigraphNC( new );
end);
#

InstallMethod(DigraphAddVertex, "for a digraph",
[IsDigraph],
function(digraph)
  return DigraphAddVerticesNC(digraph, 1, [ ]); 
end);

InstallMethod(DigraphAddVertex, "for a digraph and an object",
[IsDigraph, IsObject],
function(digraph, name)
  return DigraphAddVerticesNC(digraph, 1, [ name ]); 
end);

#

InstallMethod(DigraphAddVertices, "for a digraph and a pos int",
[IsDigraph, IsInt],
function(digraph, m)
  if m < 0 then
    Error("Digraphs: DigraphAddVertices: usage,\n",
    "the second arg <m> (the number of vertices to add) must be non-negative,");
    return;
  fi;
  return DigraphAddVerticesNC(digraph, m, [ ]);
end);

InstallMethod(DigraphAddVertices, "for a digraph, a pos int and a list",
[IsDigraph, IsInt, IsList],
function(digraph, m, names)
  if m < 0 then
    Error("Digraphs: DigraphAddVertices: usage,\n",
    "the second arg <m> (the number of vertices to add) must be non-negative,");
    return;
  elif Length(names) <> m then
    Error("Digraphs: DigraphAddVertices: usage,\n",
      "the number of new vertex names (the length of the third arg <names>)\n",
      "must match the number of new vertices (the value of the second arg <m>),"
    );
    return;
  fi;
  return DigraphAddVerticesNC(digraph, m, names);
end);

#

InstallMethod(DigraphAddVerticesNC,
"for a digraph with source, a pos int and a list",
[IsDigraph and HasDigraphSource, IsInt, IsList],
function(digraph, m, names)
  local s, r, n, out, nam;
  
  s := DigraphSource(digraph);
  r := DigraphRange(digraph);
  n := DigraphNrVertices(digraph);
  out := DigraphNC( rec( nrvertices := n + m, source := s, range := r ) );
  # Transfer known data
  if IsEmpty(names) then
    names := [ (n + 1) .. (n + m) ];
  fi;
  nam := Concatenation(DigraphVertexNames(digraph), names);
  SetDigraphVertexNames(out, nam);
  return out;
end);

InstallMethod(DigraphAddVerticesNC,
"for a digraph with out-neighbours, a pos int and a list",
[IsDigraph and HasOutNeighbours, IsInt, IsList],
function(digraph, m, names)
  local out, new, n, newverts, nam, i;
  
  out := OutNeighbours(digraph);
  new := ShallowCopy(out);
  n := DigraphNrVertices(digraph);
  newverts := [ (n + 1) .. (n + m) ];
  for i in newverts do
    new[i] := [ ];
  od;
  out := DigraphNC(new);
  # Transfer known data
  if IsEmpty(names) then
    names := newverts;
  fi;
  nam := Concatenation(DigraphVertexNames(digraph), names);
  SetDigraphVertexNames(out, nam);
  return out;
end);

#

InstallMethod(DigraphRemoveVertex, "for a digraph and a pos int",
[IsDigraph, IsPosInt],
function(digraph, m)
  if m > DigraphNrVertices(digraph) then
    Error("Digraphs: DigraphRemoveVertices: usage,\n",
    "the second arg <m> is not a vertex of the first arg <digraph>,");
    return;
  fi;
  return DigraphRemoveVerticesNC(digraph, [ m ]);
end);

#

InstallMethod(DigraphRemoveVertices, "for a digraph and a list",
[IsDigraph, IsList],
function(digraph, verts)
  local n;
  
  n := DigraphNrVertices(digraph);
  if not IsEmpty(verts) and 
   (not IsPosInt(verts[1]) or
    not IsHomogeneousList(verts) or
    not IsDuplicateFreeList(verts) or
    ForAny(verts, x -> x < 1 or n < x)) then
    Error("Digraphs: DigraphRemoveVertices: usage,\n",
      "the second arg <verts> should be a duplicate free list of vertices of\n",
      "the first arg <digraph>, specifically: a subset of [ 1 .. ", n, " ],");
    return;
  fi;
  return DigraphRemoveVerticesNC(digraph, verts );
end);

#

InstallMethod(DigraphRemoveVerticesNC,
"for a digraph with source and a list",
[IsDigraph and HasDigraphSource, IsList],
function(digraph, verts)
  local n, len, newnrverts, diff, news, newr, lookup, count, m, source, range, 
        log, gr, i;

  n := DigraphNrVertices(digraph);
  len := Length(verts);
  newnrverts := n - len;
  diff := Difference(DigraphVertices(digraph), verts);
  if IsEmpty(verts) then
    news := ShallowCopy(DigraphSource(digraph));
    newr := ShallowCopy(DigraphRange(digraph));
  else
    if newnrverts = 0 then
      return EmptyDigraph(0);
    fi;
    lookup := EmptyPlist(n);
    count := 0;
    for i in diff do
      count := count + 1;
      lookup[ i ] := count;
    od;
    m      := DigraphNrEdges(digraph);
    source := DigraphSource(digraph);
    range  := DigraphRange(digraph);
    news   := EmptyPlist(m);
    newr   := EmptyPlist(m);
    count  := 0;
    log    := LogInt(len, 2);
    if (2 * m * log) + (len * log) < (2 * m * len) then # Sort verts if sensible
      Sort(verts);
    fi;
    for i in [ 1 .. m ] do
      if not (source[i] in verts or range[i] in verts) then
        count := count + 1;
        news[ count ] := lookup[ source[i] ];
        newr[ count ] := lookup[ range[i] ];
      fi;
    od;
    ShrinkAllocationPlist(news);
    ShrinkAllocationPlist(newr);
  fi;
  gr := DigraphNC( rec( nrvertices := newnrverts,
                        source := news, range := newr ) );
  SetDigraphVertexNames(gr, DigraphVertexNames(digraph){diff});
  # Transfer data
  return gr;
end);

InstallMethod(DigraphRemoveVerticesNC,
"for a digraph with out-neighbours and a list",
[IsDigraph and HasOutNeighbours, IsList],
function(digraph, verts)
  local diff, new, n, len, newnrverts, lookup, count, out, m, log, gr, i;
  
  diff := Difference(DigraphVertices(digraph), verts);
  if IsEmpty(verts) then
    new := List( OutNeighbours(digraph), ShallowCopy );
  else
    n := DigraphNrVertices(digraph);
    len := Length(verts);
    newnrverts := n - len;
    if newnrverts = 0 then
      return EmptyDigraph(0);
    fi;
    lookup := EmptyPlist(n);
    count := 0;
    for i in diff do
      count := count + 1;
      lookup[ i ] := count;
    od;
    out   := OutNeighbours(digraph);
    new   := EmptyPlist(newnrverts);
    count := 0;
    m     := DigraphNrEdges(digraph);
    log   := LogInt(len, 2);
    if (2 * m * log) + (len * log) < (2 * m * len) then # Sort verts if sensible
      Sort(verts);
    fi;
    for i in diff do
      count := count + 1;
      new[ count ] := List(
        Filtered( out[ i ], x -> not x in verts ), y -> lookup[ y ] );
    od;
  fi;
  gr := DigraphNC(new);
  SetDigraphVertexNames(gr, DigraphVertexNames(digraph){diff});
  # Transfer data
  return gr;
end);

#

InstallMethod(OnDigraphs, "for a digraph by adjacency and perm",
[IsDigraph and HasOutNeighbours, IsPerm],
function(graph, perm)
  local adj;

  if ForAny(DigraphVertices(graph), i-> i^perm > DigraphNrVertices(graph)) then
    Error("Digraphs: OnDigraphs: usage,\n",
    "the 2nd argument <perm> must permute the vertices ",
    "of the 1st argument <graph>,");
    return;
  fi;
  
  adj := Permuted(OutNeighbours(graph), perm);
  Apply(adj, x-> OnTuples(x, perm));

  return DigraphNC(adj);
end);

InstallMethod(OnDigraphs, "for a digraph and perm",
[IsDigraph and HasDigraphRange, IsPerm],
function(graph, perm)
  local source, range;

  if ForAny(DigraphVertices(graph), i-> i^perm > DigraphNrVertices(graph)) then
    Error("Digraphs: OnDigraphs: usage,\n",
    "the 2nd argument <perm> must permute the vertices ",
    "of the 1st argument <graph>,");
    return;
  fi;
  source := ShallowCopy(OnTuples(DigraphSource(graph), perm));
  range := ShallowCopy(OnTuples(DigraphRange(graph), perm));
  range := Permuted(range, Sortex(source));
  return DigraphNC(rec(
    source := source,
    range := range,
    nrvertices:=DigraphNrVertices(graph)));
end);

#

InstallMethod(DigraphSymmetricClosure, "for a digraph",
[IsDigraph],
function(digraph)
  local n, verts, mat, m, source, range, s, r, x, out, i, j, k;
  
  source := ShallowCopy(DigraphSource(digraph));
  range  := ShallowCopy(DigraphRange(digraph));
  n := DigraphNrVertices(digraph);
  
  if not (HasIsSymmetricDigraph(digraph) and IsSymmetricDigraph(digraph))
   and n > 1 then
    verts := ShallowCopy(DigraphVertices(digraph));
    mat := List( verts, x -> verts * 0 );
    m := DigraphNrEdges(digraph);
    source := ShallowCopy(DigraphSource(digraph));
    range  := ShallowCopy(DigraphRange(digraph));
    for i in [ 1 .. m ] do
      s := source[i];
      r := range[i];
      if r < s then
        mat[r][s] := mat[r][s] - 1;
      else
        mat[s][r] := mat[s][r] + 1;
      fi;
    od;
    for i in verts do
      for j in [ i + 1 .. n ] do
        x := mat[i][j];
        if x > 0 then
          for k in [ 1 .. x ] do
            m := m + 1;
            source[m] := j;
            range[m] := i;
          od;
        elif x < 0 then
          for k in [ 1 .. -x ] do
            m := m + 1;
            source[m] := i;
            range[m] := j;
          od;
        fi;
      od;
    od;
    range := Permuted(range, Sortex(source)); 
  fi;
  out := DigraphNC( rec( nrvertices := n, source := source, range := range ) );
  SetIsSymmetricDigraph(out, true);
  return out;
end);

#

InstallMethod(DigraphTransitiveClosure, "for a digraph",
[IsDigraph],
function(graph)
  
  if IsMultiDigraph(graph) then
    Error("Digraphs: DigraphTransitiveClosure: usage,\n",
    "the argument <graph> cannot have multiple edges,");
    return;
  fi;

  return DigraphTransitiveClosure(graph, false);
end);

#

InstallMethod(DigraphReflexiveTransitiveClosure, "for a digraph",
[IsDigraph],
function(graph)

  if IsMultiDigraph(graph) then
    Error("Digraphs: DigraphReflexiveTransitiveClosure: usage,\n",
    "the argument <graph> cannot have multiple edges,");
    return;
  fi;

  return DigraphTransitiveClosure(graph, true); 
end);

#

InstallMethod(DigraphTransitiveClosure, "for a digraph and a boolean", 
[IsDigraph, IsBool],
function(graph, reflexive)
  local n, vertices, adj, sorted, out, trans, reflex, mat, v, u;

  n := DigraphNrVertices(graph);
  vertices := DigraphVertices(graph);
  adj := OutNeighbours(graph);
  sorted := DigraphTopologicalSort(graph);

  if sorted <> fail then # Easier method for acyclic graphs (loops allowed)
    out := EmptyPlist(n);
    trans := EmptyPlist(n);

    for v in sorted do
      trans[v] := BlistList( vertices, [v]);
      reflex := false;
      for u in adj[v] do
        trans[v] := UnionBlist(trans[v], trans[u]);
        if u = v then
          reflex := true;
        fi;
      od;
      if (not reflexive) and (not reflex) then
        trans[v][v] := false;
      fi;
      out[v] := ListBlist(vertices, trans[v]);
      trans[v][v] := true;
    od;

    out := DigraphNC(out);
  else # Non-acyclic: C method
    if reflexive then
      mat := DIGRAPH_REFLEX_TRANS_CLOSURE(graph);
    else
      mat := DIGRAPH_TRANS_CLOSURE(graph);
    fi;
    out := DigraphByAdjacencyMatrixNC(mat);
  fi;
  SetIsMultiDigraph(out, false);
  SetIsTransitiveDigraph(out, true);
  return out;
end);

#

InstallMethod(InducedSubdigraph, 
"for a digraph with out neighbours and a homogeneous list",
[IsDigraph and HasOutNeighbours, IsHomogeneousList],
function( digraph, subverts )
  local n, old, nr, lookup, adj, j, l, i, k, new;

  if IsEmpty(subverts) then
    return DigraphNC( [ ] );
  fi;

  n := DigraphNrVertices(digraph);
  if (IsRange(subverts) and not (IsPosInt(subverts[1]) and subverts[1] <= n and
    subverts[Length(subverts)] <= n))
    or not IsDuplicateFree(subverts)
    or not ForAll( subverts, x -> IsPosInt(x) and x < (n + 1)) then
    Error("Digraphs: InducedSubdigraph: usage,\n",
    "the second argument <subverts> must be a duplicate-free subset\n",
    "of the vertices of the first argument <digraph>,");
    return;
  fi;
  
  Sort(subverts); # Sorting for consistency with Source/Range version
  nr := Length(subverts);
  old := OutNeighbours(digraph);
  new := EmptyPlist(nr);
  lookup := [ 1 .. n ] * 0;
  lookup{subverts} := [ 1 .. nr ];

  for i in [ 1 .. nr ] do 
    adj := [ ];
    j := 0;
    for k in old[ subverts[i] ] do
      l := lookup[k];
      if l <> 0 then
        j := j + 1;
        adj[j] := l;
      fi;
    od;
    new[i] := adj;
  od;
  
  new := DigraphNC(new);
  SetDigraphVertexNames(new, DigraphVertexNames(digraph){subverts});
  return new;
end);

#

InstallMethod(InducedSubdigraph, "for a digraph with digraph source and a list",
[IsDigraph and HasDigraphSource, IsHomogeneousList], 1,
function( digraph, subverts )
  local n, lookup, nr, source, range, news, newr, current, count, source_in,
  allowed, new, i;

  if IsEmpty(subverts) then
    return DigraphNC( [ ] );
  fi;

  n := DigraphNrVertices(digraph);
  if (IsRange(subverts) and not (IsPosInt(subverts[1]) and subverts[1] <= n and
    subverts[Length(subverts)] <= n))
    or not IsDuplicateFree(subverts)
    or not ForAll( subverts, x -> IsPosInt(x) and x < (n + 1)) then
    Error("Digraphs: InducedSubdigraph: usage,\n",
    "the second argument <subverts> must be a duplicate-free subset\n",
    "of the vertices of the first argument <digraph>,");
    return;
  fi;

  Sort(subverts); # Sorting to ensure new source will be sorted
  lookup := EmptyPlist( n );
  nr := Length(subverts);
  for i in [ 1 .. nr ] do
    lookup[ subverts[i] ] := i;
  od;

  source  := DigraphSource(digraph);
  range   := DigraphRange(digraph);
  news      := [ ];
  newr      := [ ];
  current   := 0;
  count     := 0;
  source_in := false;
  allowed   := BlistList( DigraphVertices(digraph), subverts );

  for i in [ 1 .. Length(source) ] do
    if source[i] <> current then
      current   := source[i];
      source_in := allowed[current];
    fi;
    if source_in and allowed[range[i]] then
      count        := count + 1;
      news[count]  := lookup[current];
      newr[count]  := lookup[range[i]];
    fi;
  od;

  new := DigraphNC( rec ( nrvertices := nr, source := news, range := newr ) );
  SetDigraphVertexNames(new, DigraphVertexNames(digraph){subverts});
  return new;

end);

#

InstallMethod(InNeighborsOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  return InNeighboursOfVertex(digraph, v);
end);

InstallMethod(InNeighboursOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: InNeighboursOfVertex: usage,\n",
          "the second argument <v> is not a vertex of the first, <digraph>,");
    return;
  fi;
  return InNeighboursOfVertexNC(digraph, v);
end);

InstallMethod(InNeighboursOfVertexNC, "for a digraph with in-neighbours and a vertex",
[IsDigraph and HasInNeighbours, IsPosInt], 3,
function(digraph, v)
  return InNeighbours(digraph)[v];
end);

InstallMethod(InNeighboursOfVertexNC, "for a digraph with out-neighbours and a vertex",
[IsDigraph and HasOutNeighbours, IsPosInt],
function(digraph, v)
  local inn, pos, out, i, j;

  inn := [];
  pos := 1;
  out := OutNeighbours(digraph);
  for i in [ 1 .. Length(out) ] do
    for j in [ 1 .. Length(out[i]) ] do
      if out[i][j] = v then
        inn[pos] := i;
        pos := pos + 1;
      fi;
    od;
  od;
  return inn;
end);

InstallMethod(InNeighboursOfVertexNC, "for a digraph with range/source and a vertex",
[IsDigraph and HasDigraphRange, IsPosInt], 1,
function(digraph, v)
  local inn, pos, source, range, i;

  inn := [];
  pos := 1;
  source := DigraphSource(digraph);
  range := DigraphRange(digraph);
  for i in [ 1 .. Length(range) ] do
    if range[i] = v then
      inn[pos] := source[i];
      pos := pos + 1;
    fi;
  od;
  return inn;
end);

#

InstallMethod(OutNeighborsOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  return OutNeighboursOfVertex(digraph, v);
end);

InstallMethod(OutNeighboursOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: OutNeighboursOfVertex: usage,\n",
          "the second argument <v> is not a vertex of the first, <digraph>,");
    return;
  fi;
  return OutNeighboursOfVertexNC(digraph, v);
end);

InstallMethod(OutNeighboursOfVertexNC, "for a digraph with out-neighbours and a vertex",
[IsDigraph and HasOutNeighbours, IsPosInt],
function(digraph, v)
  return OutNeighbours(digraph)[v];
end);

InstallMethod(OutNeighboursOfVertexNC, "for a digraph with only source/range and a vertex",
[IsDigraph and HasDigraphRange, IsPosInt], 1,
function(digraph, v)
  local out, pos, source, range, m, i;

  out := [];
  pos := 1;
  source := DigraphSource(digraph);
  range := DigraphRange(digraph);
  m := Length(source);
  i := PositionSorted(source, v);
  if i <> fail then
    while i <= m and source[i] = v do
      out[pos] := range[i];
      pos := pos + 1;
      i := i + 1;
    od;
  fi;
  return out;
end);

#

InstallMethod(InDegreeOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: InDegreeOfVertex: usage,\n",
          "the second argument <v> is not a vertex of the first, <digraph>,");
    return;
  fi;
  return InDegreeOfVertexNC(digraph, v);
end);

InstallMethod(InDegreeOfVertexNC, "for a digraph with in-degrees and a vertex",
[IsDigraph and HasInDegrees, IsPosInt], 4,
function(digraph, v)
  return InDegrees(digraph)[v];
end);

InstallMethod(InDegreeOfVertexNC, "for a digraph with in-neighbours and a vertex",
[IsDigraph and HasInNeighbours, IsPosInt], 3,
function(digraph, v)
  return Length(InNeighbours(digraph)[v]);
end);

InstallMethod(InDegreeOfVertexNC, "for a digraph with out-neighbours and a vertex",
[IsDigraph and HasOutNeighbours, IsPosInt],
function(digraph, v)
  local count, out, x, i;

  count := 0;
  out := OutNeighbours(digraph);
  for x in out do
    for i in x do
      if i = v then
        count := count + 1;
      fi;
    od;
  od;
  return count;
end);

InstallMethod(InDegreeOfVertexNC, "for a digraph (with only source/range) and a vertex",
[IsDigraph and HasDigraphRange, IsPosInt],
function(digraph, v)
  local range, count, i;

  range := DigraphRange(digraph);
  count := 0;
  for i in [ 1 .. Length(range) ] do
    if range[i] = v then
      count := count + 1;
    fi;
  od;
  return count;
end);

#

InstallMethod(OutDegreeOfVertex, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: OutDegreeOfVertex: usage,\n",
          "the second argument <v> is not a vertex of the first, <digraph>,");
    return;
  fi;
   return OutDegreeOfVertexNC(digraph, v);
end);

InstallMethod(OutDegreeOfVertexNC, "for a digraph with out-degrees and a vertex",
[IsDigraph and HasOutDegrees, IsPosInt], 3,
function(digraph, v)
  return OutDegrees(digraph)[v];
end);

InstallMethod(OutDegreeOfVertexNC, "for a digraph with out-neighbours and a vertex",
[IsDigraph and HasOutNeighbours, IsPosInt],
function(digraph, v)
  return Length(OutNeighbours(digraph)[v]);
end);

InstallMethod(OutDegreeOfVertexNC, "for a digraph with source/range and a vertex",
[IsDigraph and HasDigraphSource, IsPosInt], 1,
function(digraph, v)
  local count, source, m, i;

  source := DigraphSource(digraph);
  m := Length(source);
  i := PositionSorted(source, v);
  count := 0;
  if i <> fail then
    while i <= m and source[i] = v do
      i := i + 1;
      count := count + 1;
    od;
  fi;
  return count;
end);

#

InstallMethod(QuotientDigraph, "for a digraph and a homogeneous list",
[IsDigraph, IsHomogeneousList],
function(digraph, partition)
  local n, nr, check, lookup, out, new, gr, source, range, m, newsource,
  newrange, x, i, j;

  n := DigraphNrVertices(digraph);
  if n = 0 and IsEmpty(partition) then
    return EmptyDigraph(0);
  elif n = 0 then
    Error("Digraphs: QuotientDigraph: usage,\n",
          "the second argument <partition> is not a valid partition of the\n",
          "vertices of the null digraph <digraph>. The only valid partition\n",
          "of <digraph> is the empty list,");
    return;
  fi;
  nr := Length(partition);
  if n = 0 or
   nr = 0 or
   not IsList(partition[1]) or
   IsEmpty(partition[1]) or
   not IsPosInt(partition[1][1]) then
    Error("Digraphs: QuotientDigraph: usage,\n",
          "the second argument <partition> is not a valid partition\n",
          "of the vertices of <digraph>, [ 1 .. ", n, " ],");
    return;
  fi;

  check := BlistList( DigraphVertices(digraph), [  ] );
  lookup := EmptyPlist(n);
  
  for x in [ 1 .. Length(partition) ] do
    for i in partition[x] do
      if i < 1 or i > n or check[i]  then
        Error("Digraphs: QuotientDigraph: usage,\n",
          "the second argument <partition> is not a valid partition\n",
          "of the vertices of <digraph>, [ 1 .. ", n, " ],");
        return;
      fi;
      check[i] := true;
      lookup[i] := x;
    od;
  od;
  
  if ForAny( check, x -> not x ) then
    Error("Digraphs: QuotientDigraph: usage,\n",
          "the second argument <partition> does not partition\n",
          "every vertex of the first argument, <digraph>,");
    return;
  fi;

  if HasOutNeighbours(digraph) then
    out := OutNeighbours(digraph);
    new := List( [ 1 .. nr ], x -> [ ] );
    for i in DigraphVertices(digraph) do
      for j in out[i] do
        Add(new[lookup[i]], lookup[j]);
      od;
    od;
    gr := DigraphNC(new);
  elif HasDigraphRange(digraph) then
    source := DigraphSource(digraph);
    range := DigraphRange(digraph);
    m := Length(source);
    newsource := EmptyPlist(m);
    newrange := EmptyPlist(m);
    for i in [ 1 .. m ] do
      newsource[i] := lookup[source[i]];
      newrange[i] := lookup[range[i]];
    od;
    newrange := Permuted(newrange, Sortex(newsource));
    gr := DigraphNC( rec( nrvertices := nr,
                          source     := newsource,
                          range      := newrange ) );
  fi;

  # Pass on information about <digraph> which might be relevant to gr?
  return gr;
end);

#

InstallMethod(DigraphOutEdges, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: DigraphOutEdges: usage,\n",
          v, " is not a vertex of the digraph,");
    return;
  fi;

  return List(OutNeighboursOfVertex(digraph, v), x -> [v, x]);
end);

#

InstallMethod(DigraphInEdges, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  if not v in DigraphVertices(digraph) then
    Error("Digraphs: DigraphInEdges: usage,\n",
          v, " is not a vertex of the digraph,");
    return;
  fi;

  return List(InNeighboursOfVertex(digraph, v), x -> [x, v]);
end);

#

InstallMethod(DigraphStronglyConnectedComponent, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, v)
  local scc;

  if not v in DigraphVertices(digraph) then
    Error("Digraphs: DigraphStronglyConnectedComponent: usage,\n",
          v, " is not a vertex of the digraph,");
    return;
  fi;

  scc := DigraphStronglyConnectedComponents(digraph);
  return scc.comps[scc.id[v]];
end);

#

InstallMethod(IsDigraphEdge, "for a digraph with out-neighbours and a list",
[IsDigraph and HasOutNeighbours, IsList], 1,
function(digraph, edge)
  local n;

  n := DigraphNrVertices(digraph);
  if Length(edge) <> 2 or
   not IsPosInt(edge[1]) or
   not IsPosInt(edge[2]) or
   n < edge[1] or
   n < edge[2] then
    return false;
  elif edge[2] in OutNeighboursOfVertex(digraph, edge[1]) then
    return true;
  fi;
  return false;
end);

#

InstallMethod(IsDigraphEdge, "for a digraph and a list",
[IsDigraph and HasDigraphRange, IsList],
function(digraph, edge)
  local edge_src, edge_rng, n, source, range, pos, i;

  if Length(edge) <> 2 then
    return false;
  fi;

  edge_src := edge[1];
  edge_rng := edge[2];
  n := DigraphNrVertices(digraph);

  if not IsPosInt(edge_src) or
   not IsPosInt(edge_rng) or
   n < edge_src or
   n < edge_rng then
    return false;
  fi;

  source := DigraphSource(digraph);
  range := DigraphRange(digraph);
  pos := PositionSorted(source, edge_src);
  if pos <> fail then
    for i in [ pos .. Length(source) ] do
      if source[i] = edge_src and range[i] = edge_rng then
        return true;
      elif source[i] > edge_src then
        return false;
      fi;
    od;
  fi;
  return false;
end);

#

InstallMethod(AsBinaryRelation, "for a digraph",
[IsDigraph],
function(digraph)
  local rel;
  
  if DigraphNrVertices(digraph) = 0 then
    Error("Digraphs: AsBinaryRelation: usage,\n",
          "the argument <digraph> must have at least one vertex,");
    return;
  elif IsMultiDigraph(digraph) then
    Error("Digraphs: AsBinaryRelation: usage,\n",
          "this function does not apply to digraphs with multiple edges,");
    return;
  fi;
  # Can translate known attributes of <digraph> to the relation, e.g. symmetry
  rel := BinaryRelationOnPointsNC(OutNeighbours(digraph));
  if HasIsReflexiveDigraph(digraph) then
    SetIsReflexiveBinaryRelation(rel, IsReflexiveDigraph(digraph));
  fi;
  if HasIsSymmetricDigraph(digraph) then
    SetIsSymmetricBinaryRelation(rel, IsSymmetricDigraph(digraph));
  fi;
  if HasIsTransitiveDigraph(digraph) then
    SetIsTransitiveBinaryRelation(rel, IsTransitiveDigraph(digraph));
  fi;
  if HasIsAntisymmetricDigraph(digraph) then
    SetIsAntisymmetricBinaryRelation(rel, IsAntisymmetricDigraph(digraph));
  fi;
  return rel;
end);

#

InstallMethod(DigraphDisjointUnion, "for two digraphs",
[IsDigraph and HasDigraphSource, IsDigraph and HasDigraphSource], 1,
function(digraph1, digraph2)
  local nrvertices1, range, source;

  nrvertices1 := DigraphNrVertices(digraph1); 
  range := Concatenation(DigraphRange(digraph1), DigraphRange(digraph2) +
	   nrvertices1);
  source := Concatenation(DigraphSource(digraph1), DigraphSource(digraph2) +
	   nrvertices1);
  return DigraphNC(rec(nrvertices := nrvertices1 + DigraphNrVertices(digraph2),
                       source := source, range := range));
end);

#

InstallMethod(DigraphDisjointUnion, "for two digraphs",
[IsDigraph and HasOutNeighbours, IsDigraph and HasOutNeighbours], 1,
function(digraph1, digraph2)
  local nrvertices1, out2;

  nrvertices1 := DigraphNrVertices(digraph1);
  out2 := List(OutNeighbours(digraph2), x -> x + nrvertices1);

  return DigraphNC(Concatenation(OutNeighbours(digraph1), out2));
end);

#

InstallMethod(DigraphDisjointUnion, "for two digraphs",
[IsDigraph and HasDigraphSource, IsDigraph and HasOutNeighbours],
function(digraph1, digraph2)
  DigraphSource(digraph2);
  return DigraphDisjointUnion(digraph1, digraph2); 
end);

#

InstallMethod(DigraphDisjointUnion, "for two digraphs",
[IsDigraph and HasOutNeighbours, IsDigraph and HasDigraphSource],
function(digraph1, digraph2)
  DigraphSource(digraph1);
  return DigraphDisjointUnion(digraph1, digraph2); 
end);
#EOF
