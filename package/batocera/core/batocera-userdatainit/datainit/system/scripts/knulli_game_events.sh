#!/bin/bash
LOG_FILE=/userdata/system/logs/knulli-game-events.log
IN_GAME_FLAG=/var/run/in-game.flag

# Ensure the log file exists
[ ! -f "$LOG_FILE" ] && touch "$LOG_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S'): knulli_game_events.sh beginning executing" && echo >> $LOG_FILE
echo "The following parameters were passed to this script: $*" >> $LOG_FILE

# Case selection for first parameter parsed, our event.
case $1 in
    gameStart)
        # Commands in here will be executed on the start of any game.
        touch "$IN_GAME_FLAG"
        echo "$(date '+%Y-%m-%d %H:%M:%S'): Created in-game.flag..." >> $LOG_FILE
    ;;
    gameStop)
        # Commands in here will be executed on the stop of any game.
        rm -f "$IN_GAME_FLAG"
        echo "$(date '+%Y-%m-%d %H:%M:%S'): Removed in-game.flag..." >> $LOG_FILE
    ;;
esac

echo "$(date '+%Y-%m-%d %H:%M:%S'): knulli_game_events.sh completed execution." >> $LOG_FILE
