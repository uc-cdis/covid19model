# Grabs the groupedState files from https://visitdata.org/data and concatenates the files

rm 'visit-data/visitdata-grouped.csv'
touch 'visit-data/visitdata-grouped.csv'

# states="Alaska Arizona Arkansas California Colorado Connecticut Delaware Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota Mississippi Missouri Montana Nebraska Nevada NewHampshire NewJersey NewMexico NewYork NorthCarolina NorthDakota Ohio Oklahoma Oregon Pennsylvania RhodeIsland SouthCarolina SouthDakota Tennessee Texas Utah Vermont Virginia Washington WestVirginia Wisconsin Wyoming"
states="Illinois"

# Get header from Alabama
echo "Alabama"
wget -q "https://visitdata.org/data/groupedAlabama.csv" -O "visit-data/Alabama.csv"
cat "visit-data/Alabama.csv" >> 'visit-data/visitdata-grouped.csv'
rm "visit-data/Alabama.csv"

for state in $states;
do
    echo ${state}
    wget -q "https://visitdata.org/data/grouped${state}.csv" -O "${state}.csv"
    tail -n +2 "${state}.csv" >> 'visit-data/visitdata-grouped.csv'
    rm "${state}.csv"
done