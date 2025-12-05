# explicit constructor declaration
```cpp
    explicit constructor(std::string some string); 
```

**Why?** used to prevent unintended type conversion

this makes the constructor more unpredictable 

will only be able to construct the object with constructor("hello");

constructor hello = "hej" wont work 

can only use example one  and because of that you cannot pass the wrong type as arguments.


# what is an interface?
interface is the possibilities to interact with something? what the guildines /blueprints of an object.

how you could interact with the objects and methods in a class?
bird = pinguin can be used with i cantfly()
bird = eagle can be used with i canfly()



# exceptions
jag sätter bitar i en bit mask för vad den ska triggas på för typ av error och att den sätter error till typen failure
som jag kan fånga med catch keyword

