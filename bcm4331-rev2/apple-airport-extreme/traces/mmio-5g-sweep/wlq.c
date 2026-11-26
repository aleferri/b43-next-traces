/*
 * wlq <ifname> get <iovar> | set <iovar> <int> | cnt
 *     | ioc <cmd> [int...]   (get-ioctl, buffer preloaded with the ints, prints first words back)
 *     | sioc <cmd> [int...]  (set-ioctl with the ints)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <linux/sockios.h>

typedef struct { unsigned cmd; void *buf; unsigned len; uint8_t set; unsigned used, needed; } wl_ioctl_t;

static int wlio(int s, const char *ifn, unsigned cmd, void *buf, unsigned len, int set)
{
	struct ifreq ifr = {0};
	wl_ioctl_t io = { cmd, buf, len, set, 0, 0 };
	strncpy(ifr.ifr_name, ifn, IFNAMSIZ - 1);
	ifr.ifr_data = (void *)&io;
	return ioctl(s, SIOCDEVPRIVATE, &ifr);
}

static const char *cn[] = { "txframe","txbyte","txretrans","txerror","txctl","txprshort","txserr","txnobuf","txnoassoc","txrunt","txchit","txcmiss","txuflo","txphyerr","txphycrs","rxframe","rxbyte","rxerror","rxctl","rxnobuf","rxnondata","rxbadds","rxbadcm","rxfragerr","rxrunt","rxgiant","rxnoscb","rxbadproto","rxbadsrcmac","rxbadda","rxfilter","rxoflo","rxuflo","txrts_off","rxcrc_off","txnocts_off","dmade","dmada","dmape","reset","tbtt","txdmawar","pkt_cb_fail","txallfrm","txrtsfrm","txctsfrm","txackfrm","txdnlfrm","txbcnfrm","txfunfl","txtplunfl","txphyerror","rxfrmtoolong","rxfrmtooshrt","rxinvmachdr","rxbadfcs","rxbadplcp","rxcrsglitch","rxstrt","rxdfrmucastmbss","rxmfrmucastmbss","rxcfrmucast","rxrtsucast","rxctsucast","rxackucast","rxdfrmocast","rxmfrmocast","rxcfrmocast","rxrtsocast","rxctsocast","rxdfrmmcast","rxmfrmmcast","rxcfrmmcast","rxbeaconmbss","rxdfrmucastobss","rxbeaconobss","rxrsptmout","bcntxcancl" };

int main(int argc, char **argv)
{
	char buf[4096] = {0};
	int s = socket(AF_INET, SOCK_DGRAM, 0);
	if (argc < 3) return 2;
	if (!strcmp(argv[2], "get") && argc == 4) {
		strcpy(buf, argv[3]);
		if (wlio(s, argv[1], 262, buf, sizeof(buf), 0)) { perror("get"); return 1; }
		printf("%s = %d  [", argv[3], *(int32_t *)buf); for (int i = 0; i < 8; i++) printf(" %08x", ((uint32_t *)buf)[i]); printf(" ]\n");
	} else if (!strcmp(argv[2], "set") && argc == 5) {
		int32_t v = strtol(argv[4], NULL, 0);
		size_t n = strlen(argv[3]) + 1;
		strcpy(buf, argv[3]); memcpy(buf + n, &v, 4);
		if (wlio(s, argv[1], 263, buf, n + 4, 1)) { perror("set"); return 1; }
	} else if ((!strcmp(argv[2], "ioc") || !strcmp(argv[2], "sioc")) && argc >= 4) {
		int set = argv[2][0] == 's';
		unsigned cmd = strtoul(argv[3], NULL, 0), n = argc - 4;
		for (unsigned i = 0; i < n; i++) ((int32_t *)buf)[i] = strtol(argv[4 + i], NULL, 0);
		if (wlio(s, argv[1], cmd, buf, set ? (n ? 4 * n : 4) : sizeof(buf), set)) { perror("ioc"); return 1; }
		if (!set) {
			for (unsigned i = 0; i < 8; i++) printf("0x%08x ", ((uint32_t *)buf)[i]);
			printf("\n");
		}
	} else if (!strcmp(argv[2], "cnt")) {
		strcpy(buf, "counters");
		if (wlio(s, argv[1], 262, buf, sizeof(buf), 0)) { perror("cnt"); return 1; }
		for (unsigned i = 0; i < sizeof(cn) / sizeof(cn[0]); i++) {
			uint32_t v; memcpy(&v, buf + 4 + 4 * i, 4);
			if (v) printf("%s %u\n", cn[i], v);
		}
	} else return 2;
	return 0;
}
