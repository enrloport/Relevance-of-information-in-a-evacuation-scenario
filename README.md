# evacuation
Multiagent Evacuation Scenario in NetLogo and Python

This is a multiagent evacuation simulation for NetLogo.

The first step is to model the graph, givin  to nodes and edges its properties.
Is very important to respect the structure of edges and nodes files.

Once we have the nodes file and the edges file, we have to run prelude.py with the correct input (nodes and edges file). This will generate a new nodes_NL.csv that contains the properties of the nodes, paths to exits and paths to secure rooms included.

Now we can run simulation_scenario.nlogo in NetLogo by setting as inputs the new nodes_NL.csv file and the original edges.csv file
