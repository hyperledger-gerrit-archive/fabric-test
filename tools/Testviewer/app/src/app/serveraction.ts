import { environment } from '../environments/environment';

const prod = environment.production;
const port = '3000';
const serverurl = prod ? '' : `http://localhost:${port}`;

export { serverurl }