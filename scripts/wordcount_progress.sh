#!/usr/bin/env bash

cd "$1"

log="$(git log --pretty=format:'%h %ad' --date=iso-strict)"

prev_hash="$(git status | head -1 | awk '{print($NF) }')"

echo "wordcount,timestamp" > wordcounts.csv
while IFS= read -r line; do
	hash="$(echo "$line" | awk '{print $1}')"
	time="$(echo "$line" | awk '{print $2}')"
	git checkout "$hash" || exit 1
	wordcount="$(texcount -merge -sum -q -1 ${3:-main.tex})"
	if [ ! -z $wordcount ]; then 
		echo "$wordcount,$time" >> wordcounts.csv
	fi
	if [ "$hash" == "$2" ]; then break; fi
done <<< "$log"

git checkout "$prev_hash" | exit 1

echo "
import csv
from datetime import datetime
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates as dates

with open('wordcounts.csv') as file:
    data = [row for row in csv.reader(file)][1:]

timestamps=[datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%S%z') for wordcount, timestamp in data]
wordcounts=[int(wordcount) for wordcount, timestamp in data]

start=datetime.combine(datetime.date(min(timestamps)), datetime.min.time()).timestamp()
end=max(timestamps).timestamp() + 60*60*24
increment=60*60*6

plt.figure(figsize=(12, 4))
#plt.xticks([datetime.fromtimestamp(t) for t in np.arange(start, end, increment)])
#plt.gca().xaxis.set_major_formatter(dates.DateFormatter('%Y-%m-%d %H:%M'))
#plt.gcf().autofmt_xdate()
#plt.gcf().subplots_adjust(bottom=0.25)
plt.plot(timestamps, wordcounts)

#plt.xticks(rotation=45)
plt.xlabel('timestamp')
plt.ylabel('wordcount')
plt.savefig('wordcounts.pdf')" | python3
