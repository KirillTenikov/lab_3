%% клиент - менеджер - склад - сортировка - транспортировка - склад - менеджер - клиент
-module(lab3).
-compile(export_all).

manager() ->

  receive
     done ->
       io:format("Manager: done\n");
     new_order ->
       pingLoop(pang,'pidWarehouse'),
       io:format("Manager: new client! send order to the box_office\n"),
       resolvePid(pidWarehouse) ! new_order,
       manager();
    give_order ->
       pingLoop(pang,'pidClient'),
       io:format("Manager: i get a order, give to the client \n"),
       resolvePid(pidClient) ! give_order,
       manager();
     orderFinished ->
       io:format("Manager: well done!\n"),
       manager()
end.
 

warehouse() ->

  receive
     done ->
       io:format("warehouse: done\n");
       
    give_order ->
        io:format("warehouse: get a order from delivery\n"),
        pingLoop(pang, 'pidManager'),
        resolvePid(pidManager) ! give_order;
    new_order ->
        io:format("warehouse: get a order from manager\n"),
        pingLoop(pang, 'pidSorting'),
        resolvePid(pidSorting) ! sort_order
   end,
warehouse().

sorting_center() ->

  receive
     done ->
       io:format("Sorting center: done\n");
     sort_order->
       io:format("Sorting center: i get a order!\n"),
       pingLoop(pang, 'pidDelivery'),
       io:format("Sorting center: i send order\n"),
       resolvePid(pidDelivery) ! send_order,
       sorting_center()
  end.
delivery() ->

  receive
     done ->
       io:format("Delivery: done\n");
     send_order->
       io:format("Delivery: i get a order\n"),
       pingLoop(pang, 'pidWarehouse'),
       io:format("Delivery: i send order\n"),
       resolvePid(pidWarehouse) ! give_order,
       delivery()
  end.
 

client(0, _) ->
  io:format("Client: finally done!\n"),
  pingLoop(pang, 'pidManager'),
  resolvePid(pidManager) ! done,
  
  pingLoop(pang, 'pidWarehouse'),
  resolvePid(pidBox) ! done,
  
    pingLoop(pang, 'pidSorting'),
  resolvePid(pidCook) ! done,
  
  pingLoop(pang, 'pidDelivery'),
  resolvePid(pidDelivery)!done;
  
client(Index, 0) ->

     pingLoop(pang, 'pidManager'),
     io:format("Client: new client!\n"),
     resolvePid(pidManager) ! new_order,
     client(Index, 1);
     
client(Index,1) ->
  receive
    give_order ->
       io:format("Client: order complete\n\n"),
        client(Index - 1, 0)
  end.
  
runManagerNode() ->
  global:register_name(pidManager, spawn(lab3, manager,[])).
 
runSortingNode() ->
  global:register_name(pidSorting, spawn(lab3, sorting_center,[])).
 
runWarehouseNode() ->
  global:register_name(pidWarehouse, spawn(lab3, warehouse,[])).
  
runDeliveryNode() ->
  global:register_name(pidDelivery, spawn(lab3, delivery,[])). 

runClientNode(N) ->
  global:register_name(pidClient, spawn(lab3,client, [N, 0])).
 
%% ==============================================
%% Internal functions
%% =================================================
resolvePid(Atom) ->
  global:whereis_name(Atom).
 
buildNodeAddress(Atom) ->

    list_to_atom(string:concat(erlang:atom_to_list(Atom), "@192.168.2.19")).
 
pingLoop(pong, NodeName) ->
  checkNodeByName(resolvePid(NodeName), NodeName),
  pingOK;
  
pingLoop(pang, NodeName) ->
  timer:sleep(3333),
  pingLoop(net_adm:ping(buildNodeAddress(NodeName)), NodeName).
 
checkNodeByName(undefined, NodeName) ->
  pingLoop(pang, NodeName);
  
checkNodeByName(_, _) ->
  checkOK.
