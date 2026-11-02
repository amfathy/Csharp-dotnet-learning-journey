    using System;
    using System.Collections.Generic;
    using System.Linq;

namespace LinqSession15Tasks
{
    class Graph
    {
        private Dictionary<char, HashSet<char>> _adjacencyList = new Dictionary<char, HashSet<char>>();

        public void addVertex(char c)
        {
            if (!_adjacencyList.ContainsKey(c))
            {
                _adjacencyList[c] = new HashSet<char>();
            }
        }
        public void AddEdge_DirectedGraph(char source, char distination)
        {
            addVertex(source);
            addVertex(distination);
            _adjacencyList[source].Add(distination);
        }
        public void AddEdge_UdirectedGraph(char source, char distination)
        {
            addVertex(source);
            addVertex(distination);
            _adjacencyList[source].Add(distination);
            _adjacencyList[distination].Add(source);
        }

        void printGraph()
        {
            foreach (var vertex in _adjacencyList)
            {
                Console.WriteLine(vertex.Key);
                foreach (var edge in vertex.Value)
                {
                    Console.WriteLine($"   -> {edge}");
                }
            }
        }


        public void BreadthFirstTraversal(char start =' ')
        {
            if (_adjacencyList.Count == 0)
                return;

            Queue<char> TraversalQueue = new Queue<char>(_adjacencyList.Count);
           HashSet<char> visisted = new HashSet<char>();
            
            char current;
            if (_adjacencyList.Keys.Contains(start))
                current = start;
            else
                current = _adjacencyList.Keys.First();

            TraversalQueue.Enqueue(current);
            visisted.Add(current);  

            while (TraversalQueue.Count>0)
            {
                current = TraversalQueue.Dequeue();
                Console.WriteLine(current);
                
                foreach (var neigbour in _adjacencyList[current])
                {   
                    if(visisted.Add(neigbour))
                    {
                        TraversalQueue.Enqueue(neigbour); 
                    }
                }

            } 
        }

        //BreadthFirstTraversalAll()
        //DFS
        //DFSAll()
    }
    internal class Program
    {
        static void Main(string[] args)
        {
            Graph Directedgraph = new Graph();
            Directedgraph.addVertex('a');
            Directedgraph.addVertex('b');
            Directedgraph.addVertex('b');
            Directedgraph.addVertex('c');
            Directedgraph.AddEdge_DirectedGraph('d', 'a');
            Directedgraph.AddEdge_DirectedGraph('b', 'b');
            Directedgraph.AddEdge_DirectedGraph('b', 'c');
            //Directedgraph.printGraph();

            Graph UnDirectedGraph = new Graph();
            UnDirectedGraph.addVertex('a');
            UnDirectedGraph.addVertex('b');
            UnDirectedGraph.addVertex('b');
            UnDirectedGraph.addVertex('c');
            UnDirectedGraph.AddEdge_UdirectedGraph('d', 'a');
            UnDirectedGraph.AddEdge_UdirectedGraph('b', 'b');
            UnDirectedGraph.AddEdge_UdirectedGraph('b', 'c');
            //UnDirectedGraph.printGraph();


            UnDirectedGraph.BreadthFirstTraversal('b');
        }
    }
    
}