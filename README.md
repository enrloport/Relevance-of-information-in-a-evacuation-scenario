# evacuation
Multiagent Evacuation Scenario in NetLogo and Python

This is a multiagent evacuation simulation for NetLogo.

The first step is to model the graph, givin  to nodes and edges its properties.
Is very important to respect the structure of edges and nodes files.

Once we have the nodes file and the edges file, we have to run setup.py with the correct input (nodes and edges files). This will generate a new nodes_NL.csv that contains the properties of the nodes, paths to exits and paths to secure rooms included.

Now we can run evacuation_scenario.nlogo in NetLogo. It reads the new nodes_NL.csv file and the original edges.csv file to make the graph


You can find other utilities in the extras folder.
The file social_forces.nlogo is an adapted implementation of the work made by Dirk Helbing y Péter Molnár in https://journals.aps.org/pre/abstract/10.1103/PhysRevE.51.4282 
