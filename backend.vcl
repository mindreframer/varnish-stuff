backend default {
    .host = "127.0.0.1";
    .port = "80";
    .probe = {
        .url = "/ping";
        .timeout  = 1s;
        .interval = 10s;
        .window    = 5;
        .threshold = 2;
    }
    .first_byte_timeout = 300s;
}
