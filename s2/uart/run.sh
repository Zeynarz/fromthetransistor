#!/bin/bash
iverilog -o final uart.v uart_tb.v
vvp final
