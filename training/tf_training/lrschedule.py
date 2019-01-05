from collections import deque

import tensorflow as tf

from utils import TrainLogger


class AutoDrop:
    def __init__(self, sess, max_range=800, min_lr=1e-5, threshold=0.01):
        self.min_lr = min_lr
        self.max_range = max_range
        self.drop_count = 0
        self.drop_threshold = threshold
        self.loss_record = deque(maxlen=self.max_range)
        self.logger = TrainLogger().logger
        self.sess = sess

        # initial learning rate
        self.lr = tf.Variable(0.1, dtype=tf.float32, name='lr', trainable=False)

    def step(self, loss):
        self.loss_record.append(loss)
        # keep this for more debug info
        self.logger.debug(self.loss_record)
        if len(self.total_loss_record) >= self.loss_range:
            first_loss = self.loss_record[0]
            last_loss = self.loss_record[-1]
            mean_loss = (first_loss + last_loss) / 2
            drop_rate = (first_loss - last_loss) / mean_loss

            if drop_rate < self.drop_threshold:
                self.drop_count += 1
                self.logger.info("Learning rate ready to drop count = {}".format(
                    self.drop_count))

                # drop lr only when the loss really has no progress.
                # this will avoid some false alarms.
                if self.drop_count > 5:
                    self.logger.info("First loss {:g}, last loss {:g}".format(
                        first_loss, last_loss))
                    self.logger.info("Total loss drop rate {:g} < {:g}, auto drop learning rate.".format(
                        drop_rate, self.drop_threshold))
                    # if no enough progress, drop the learning rate
                    self.sess.run(tf.assign(self.lr, self.lr * 0.1))
                    # reset loss record and count
                    self.loss_record.clear()
                    self.drop_count = 0
        return self.sess.run(self.lr)
