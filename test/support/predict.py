import pandas as pd
from outliertree import OutlierTree

train_df = pd.read_csv('test/support/train.csv', float_precision='high')
test_df = pd.read_csv('test/support/test.csv', float_precision='high')

model = OutlierTree(nthreads=1)
model.fit(train_df, outliers_print=0)

# unseen values
# test_df.loc[-2, 'categ_col'] = 'categD'
# test_df.loc[-1, 'categ_col'] = 'categE'

predictions = model.predict(test_df)
outliers = predictions[predictions['outlier_score'].notnull()].to_dict('records')
print(outliers)
