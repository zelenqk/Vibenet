globalvar client, console, dt;

client = new main();
client.connect();

console = new terminal();

targetDt = 1 / 60;
dt = (delta_time / targetDt) / 1000000