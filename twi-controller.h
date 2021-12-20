#ifndef __TWI_H__
#define __TWI_H__

void TWI_INITIALIZE();
void TWI_SEND_S();
void TWI_SEND_P();
unsigned int TWI_SEND_SLA_R(char address);
unsigned int TWI_SEND_SLA_W(char address);
unsigned int TWI_SEND(char data);
unsigned int TWI_RECV_ACK();
unsigned int TWI_RECV_NACK();

#endif /* __TWI_H__ */
