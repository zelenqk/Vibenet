globalvar client, console, dt;

client = new main();
client.connect();

console = new debugger();

targetDt = 1 / 60;
dt = (delta_time / targetDt) / 1000000