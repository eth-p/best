# ----------------------------------------------------------------------------------------------------------------------
# best | Copyright (C) 2020 eth-p | MIT License
#
# Repository: https://github.com/eth-p/best
# Issues:     https://github.com/eth-p/best/issues
# ----------------------------------------------------------------------------------------------------------------------
__BEST_RESULT_ENUM_PASS="PASS"
__BEST_RESULT_ENUM_FAIL="FAIL"
__BEST_RESULT_ENUM_SKIP="SKIP"
__BEST_OUTPUT_ENUM_STDOUT="STDOUT"
__BEST_OUTPUT_ENUM_STDERR="STDERR"
__BEST_TIMESTAMP_ENUM_START="START"
__BEST_TIMESTAMP_ENUM_FINISH="FINISH"
# ----------------------------------------------------------------------------------------------------------------------

# Sends a TEST IPC message.
# This represents the name of the upcoming test.
#
# Arguments:
#     $1  [string]  -- The test name.
#
__best_ipc_send_test_name() {
	__best_ipc_send "TEST" "$1"
}

# Sends a TEST_OUTPUT IPC message.
# This represents a file containing one of the test's outputs.
#
# Arguments:
#     $1  [string]  -- The output type.
#     $2  [string]  -- The output file.
#
__best_ipc_send_test_output() {
	__best_ipc_send "TEST_OUTPUT" "$1 $2"
}

# Sends a TEST_TIMESTAMP IPC message.
# This represents a timestamp that can be used to calculate the test duration.
#
# Arguments:
#     $1  [string]  -- The timestamp type.
#     $2  [string]  -- The timestamp.
#
__best_ipc_send_test_timestamp() {
	__best_ipc_send "TEST_TIMESTAMP" "$1 $2"
}

# Sends a TEST_COMPLETE IPC message.
# This represents the exit code of the test.
#
# Arguments:
#     $1  [number]  -- The exit code.
#
__best_ipc_send_test_complete() {
	__best_ipc_send "TEST_COMPLETE" "$1"
}

# Sends a RESULT IPC message.
# This represents the final result of the test.
#
# Arguments:
#     $1  ["FAIL"|"PASS"|"SKIP"]  -- The result type.
#
__best_ipc_send_test_result() {
	__best_ipc_send "RESULT" "$1"
}

# Sends a RESULT_MSG IPC message.
# This represents a message that explains why the test result ended up the way it did.
#
# Arguments:
#     $1  [string]  -- The result message printf pattern.
#
__best_ipc_send_test_result_message() {
	__best_ipc_send "RESULT_MSG" "$1"
}

# Sends a RESULT_MSG_DATA IPC message.
# This represents a message that explains why the test result ended up the way it did.
#
# Arguments:
#     $1  [string]  -- The result printf argument.
#
__best_ipc_send_test_result_message_data() {
	__best_ipc_send "RESULT_MSG_DATA" "$1"
}

# Sends a RUNNER_MSG IPC message.
# This represents a generic user message, and should not be interpreted for reports.
#
# Arguments:
#     $1  [string]  -- The result message.
#
__best_ipc_send_message() {
	__best_ipc_send "RUNNER_MSG" "$1"
}

# Sends a RUNNER_CRASH IPC message.
# This represents a fatal crash that indicates the runner failed in some way.
#
# Arguments:
#     $1  [string]  -- The crash message.
#
__best_ipc_send_crash() {
	__best_ipc_send "RUNNER_CRASH" "$1"
}

# Sends a EXECUTING IPC message.
# This represents the previous command sent to the REPL.
#
# Arguments:
#     $1  [string]  -- The command.
#     $2  [string]  -- The command data.
#
__best_ipc_send_executing_message() {
	__best_ipc_send "EXECUTING" "$1 $2"
}

# Sends a raw best-runner IPC message.
#
# Arguments:
#     $1  [string]  -- The message name.
#     $2  [string]  -- The message data.
#
# Example:
#
#     __best_ipc_send "TEST_RESULT" "FAIL"
#
__best_ipc_send() {
	printf "%s %s\n" "$1" "$2" 1>&3
}
