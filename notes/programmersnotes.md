# Todo
2. Get the crossCompiler going
   3. find out compiler for raspberrypi 4 os lite
   4. implement it and build the helloworld executable and run it on raspberrypi
3. Merge project with external libraries
4. finish project structure with all modules i need
5. build all modules
6. create documents after every completed task



# logger
logga allt ifrån main?
vill kunna använda klasserna till annat. 
kasta alla throws till huvud klassen

men för information som är i min klass?
implementera logger?


# configManager

**the constructor** reads json from file stores in object and sorts out the configs needed to each sub object

this constructor reads from ifstream the json object parses the ifstream object.


if you add config keys in a json
you need to add that attribute to config manager and the extract_... method.


configManager setters will set configs for each object.



# STEG 1 
implementera logger i main.
implementera modbus rtu client i main

configManager initaliseras i main
logger initaliserar i main
modbusRTU initialiseras med configManagern
och kan logga allt som händer. då blir det att alla objekt initialiseras med loggern.

