import sys

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print "Log file expected."
        exit(1)
    files = {}
    with open(sys.argv[1], "r") as f:
        for line in f:
            l = line.split()
            if len(l) == 0 or l[0] != "Traffic":
                continue
            cycle = int(l[2])
            dsid = int(l[4])
            traffic = int(l[6])
            if dsid not in files:
                files[dsid] = open("%d.trace" % dsid,"w")
            f = files[dsid]
            f.write("%d %d\n" % (cycle, traffic))
    for dsid in files:
        files[dsid].close()
