#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jul 16 20:34:09 2019

@author: enrloport
"""
import math
from shutil import copyfile


class graph (object):
    
    def __init__(self,nodes_file,edges_file):
        self.header = ''
        self.graph = self.read_graph(edges_file)
        self.edges_file = edges_file
        self.nodes = list(self.graph.keys())
        self.nodes_own = {}
        self.exits = []
        self.secure_rooms = []        
        self.read_nodes(nodes_file)
        self.paths_to_exits = {x:[] for x in self.nodes}
        self.paths_to_secure_rooms = {x:[] for x in self.nodes}
        
        self.calculate_paths(self.exits, self.paths_to_exits)
        self.calculate_paths(self.secure_rooms, self.paths_to_secure_rooms)
        
        self.make_files('nodes_NL.csv','edges_NL.csv')
        print("\nFiles created succesfully")
    

    def read_nodes(self,nodes_file):
        with open(nodes_file) as n:
            nodes = n.readlines()
            self.header = nodes[0]
            nodes = nodes[1:]
        nodes = [ [float(y.strip())  if len(y.strip()) < 6 else y.strip() for y in x.split(',')]  for x in nodes if len(x)>1]

        for node in nodes:
            if node[0] - math.floor(node[0]) < 0.099:
                self.exits.append(node[0])
            if node[-2] == 1:
                self.secure_rooms.append(node[0])
            self.nodes_own[node[0]]=node 
        
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
    
    def node_string(self,node):
        res = ''
        for property in self.nodes_own[node]:
            res += str(property) + ','
        res += self.reacheables_string(node)
        res += ','
        res += self.exits_string(node)
        res += ','
        res += self.rooms_string(node)
        return res
    
    def reacheables_string(self,node):
        return self.list_to_string(self.graph[node])
    
    def exits_string(self,node):
        res = '['
        for path in self.paths_to_exits[node]:
            res += ' ' + str(self.list_to_string(path)) + ' '
        res += ']'
        return res 
    
    def rooms_string(self,node):
        res = '['
        for path in self.paths_to_secure_rooms[node]:
            res += ' ' + str(self.list_to_string(path)) + ' '
        res += ']'
        return res 
    
    def list_to_string(self,a_list):
        res = '['
        for item in a_list:
            res += ' ' + str(item) + ' '
        res += ']'
        return res
            
    def make_files(self, nodes, edges):
        
        copyfile(self.edges_file, 'edges_NL.csv' )        
        first_line = self.header.strip() + ', reacheables, exits_routes, rooms_routes'

        with open(nodes, "w") as fp:
            print(first_line, file = fp)
            for node in self.nodes:
                print(self.node_string(node), file = fp)        

nodes_file = "nodes.csv"
edges_file = "edges.csv"
graph = graph( nodes_file, edges_file)


