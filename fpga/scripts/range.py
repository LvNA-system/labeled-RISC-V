import sys

def prepare(file_name):
    data = {}
    with open(file_name, "r") as f:
        for line in f:
            l = line.split()
            if len(l) == 0 or l[0] != "Traffic":
                continue
            cycle = int(l[2])
            dsid = int(l[4])
            traffic = int(l[6])
            if dsid not in data:
                data[dsid] = []
            data[dsid].append([cycle, traffic])
    return data

def query(datas, dsid, start, end):
    total_traffic = 0
    for r in datas[dsid]:
        if r[0] > end:
            break
        if r[0] > start:
            total_traffic += r[1]
    return total_traffic

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print "Log file expected."
        exit(1)

    data = prepare(sys.argv[1])

    for i in range(0, 2000):
        start = 17000 * i
        end = 17000 * (i + 1)
        sample_0 = query(data, 0, start, start + 1000)
        sample_1 = query(data, 1, start, start + 1000)
        regulate_0 = query(data, 0, start + 1000, end)
        regulate_1 = query(data, 1, start + 1000, end)
        print i, "\t", sample_0, "\t", sample_1, "\t", regulate_0, "\t", regulate_1
