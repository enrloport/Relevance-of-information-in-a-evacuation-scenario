#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jul 16 20:34:09 2019

@author: enrloport
"""
import math


class graph (object):
    
    def __init__(self,nodes_file,edges_file):
        self.graph = self.read_graph(edges_file)
        self.nodes = list(self.graph.keys())
        self.nodes_own = []
        self.exits = []
        self.secure_rooms = []        
        self.read_nodes(nodes_file)
        self.paths_to_exits = {x:[] for x in self.nodes}
        self.paths_to_secure_rooms = {x:[] for x in self.nodes}
        
        self.calculate_paths(self.exits, self.paths_to_exits)
        self.calculate_paths(self.secure_rooms, self.paths_to_secure_rooms)
        
        print(self.nodes_own[0])
        print(self.paths_to_secure_rooms[self.nodes_own[0][0]])
        print(self.paths_to_exits[ self.nodes_own[0][0] ])
    

    def read_nodes(self,nodes_file):
        with open(nodes_file) as n:
            nodes = n.readlines()
#            nodes0 = nodes[0]
            nodes = nodes[1:]
        nodes = [ [float(y.strip()) for y in x.split(',')]  for x in nodes if len(x)>1]

        for node in nodes:
            if node[0] - math.floor(node[0]) < 0.099:
                self.exits.append(node[0])
            if node[-1] == 1:
                self.secure_rooms.append(node[0])
            self.nodes_own.append(node)    
        
    def read_graph(self,file):
    
        with open(file) as f:
            edges = f.readlines()
            edges = [x.split(',') for x in edges[1:] if len(x) > 1]
    
        edges = [ [float(x[0].strip()),float(x[1].strip()),float(x[2].strip())] for x in edges if x[5].strip() == '1' ]

        graph = {}

        for edge in edges:
            try:
                aux = graph[edge[0]] + [(edge[1],edge[2])] 
                aux.sort( key = lambda x: x[1] )
                graph[edge[0]] = aux
            except:
                graph[edge[0]] = [ (edge[1],edge[2]) ]

        for node in graph.keys():
            graph[node] = [x[0] for x in graph[node]]
    
        return graph
    
    def bfs(self,queue,paths,res):
        copy = queue.copy()        
        while paths != []:
            node0 = paths.pop(0)
            if node0 in copy:
                copy.remove(node0)
            for node in self.graph[node0]:
                if node in copy:
                    paths.append(node)
                    aux = [node] + res[node0]                
                    if not node in res.keys() or len(aux) < len(res[node]) :
                        res[node] = aux                  
            self.bfs(copy, paths, res)
        return res

    
    def calculate_paths(self,roots,paths):
        nodes = self.nodes        
        for e in roots:
            aux = self.bfs( nodes, [e], {e:[e]} ) 
            for node in self.nodes:
                paths[node].append(aux[node] )
        
    def make_files(self, nodes_file):
        return
        



graph = graph("nodes.csv","edges.csv")


