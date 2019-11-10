#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jul 16 20:34:09 2019

@author: Enrique Lopez Ortiz
"""

# ===========================
# PARÁMETROS DE CONFIGURACIÓN
# ===========================

# ¿Quieres preprocesar un fichero de nodos o de aristas?
el_input_es_un_fichero_de_nodos = True
# Nombre de los ficheros que se crearán
input  = "nodes2-copia.csv"
output = "nodes2.csv"




# ===========================
# FUNCIONES AUXILIARES
# ===========================

def crea_fichero_aristas(file):
    with open(file, 'r', encoding='utf-8') as infile:
        for line in infile:
            l = [x.strip() for x in line.split(",")]
            if len(l) == 8:
                escribe_arista(l[0],l[1],l[2],l[3],l[4],l[5],l[6],l[7])
                
def crea_fichero_nodos(file):
    with open(file, 'r', encoding='utf-8') as infile:
        for line in infile:
            l = [x.strip() for x in line.split(",")]
            if len(l) >= 8:
                escribe_nodo(l[0],l[1],l[2],l[3],l[4],l[5],l[6],l[7])
                

def escribe_arista(n1,n2,dist,visib,sonido,transit,lock,flow):
    arista = str(n1)+","+str(n2)+","+str(dist)+","+str(visib)+","+str(sonido)+","+str(transit)+","+str(lock)+","+str(flow)  
    with open(output, "a") as fp:
        print(arista, file = fp)

def escribe_nodo(id,x,y,size,cap,hide,info,lock):
    arista = str(id)+","+str(x)+","+str(y)+","+str(size)+","+str(cap)+","+str(hide)+","+str(info)+","+str(lock)  
    with open(output, "a") as fp:
        print(arista, file = fp)



# ===========================
# CREACIÓN DEL FICHERO
# ===========================

if el_input_es_un_fichero_de_nodos:
    crea_fichero_nodos(input)
else:
    crea_fichero_aristas(input)



